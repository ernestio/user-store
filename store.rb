# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'flowauth'
require 'sinatra'
require 'sequel'
require 'yaml'
require 'nats/client'

module Config
  def self.load_db
    NATS.start(servers: [ENV['NATS_URI']]) do
      NATS.request('config.get.postgres') do |r|
        return JSON.parse(r, symbolize_names: true)
      end
    end
  end
  def self.load_redis
    return nil if ENV['RACK_ENV'] == 'test'
    NATS.start(servers: [ENV['NATS_URI']]) do
      NATS.request('config.get.redis') do |r|
        return r
      end
    end
  end
end

class API < Sinatra::Base
  configure do
    # Default DB Name
    ENV['DB_URI'] ||= Config.load_db[:url]
    ENV['DB_REDIS'] ||= Config.load_redis
    ENV['DB_NAME'] ||= 'users'

    #  Initialize database
    Sequel::Model.plugin(:schema)
    DB = Sequel.connect("#{ENV['DB_URI']}/#{ENV['DB_NAME']}")

    #  Create users database table if does not exist
    DB.create_table? :users do
      String :user_id, null: false, primary_key: true
      String :client_id, null: false
      String :user_name, null: false
      String :user_email, null: false
      String :user_password, null: false
      String :user_salt, null: false
      String :auth_key, null: true
      TrueClass :user_admin, default: false
      unique [:user_name]
    end

    Object.const_set('UserModel', Class.new(Sequel::Model(:users)))
  end

  #  Set content type for the entire API as JSON
  before do
    content_type :json
  end

  # Every call needs to use authorization
  use Authentication

  #  GET /session
  #
  #  Fetch an user session
  get '/session/?' do
    user = UserModel.filter(auth_key: env['HTTP_X_AUTH_TOKEN']).first
    return status 404 if user.nil?
    status 200
    return { user_id:    user[:user_id],
             client_id:  user[:client_id],
             user_name:  user[:user_name],
             user_email: user[:user_email] }.to_json
  end

  #  POST /session
  #
  #  Creates an user session
  post '/session/?' do
    req_user = JSON.parse(request.body.read, symbolize_names: true)
    users = UserModel.filter(user_name:     req_user[:user_name])
    return status 403 if users.count == 0
    user = users.first
    req_pwd = Digest::SHA2.hexdigest(user[:user_salt] + req_user[:user_password])
    return status 403 if req_pwd != user[:user_password]

    auth_key = user.auth_key
    auth_key = SecureRandom.hex if AuthCache.get(auth_key).nil?
    user.auth_key = auth_key
    user.save

    AuthCache.set auth_key, { user_id: user.user_id,
                              client_id: user.client_id,
                              user_name: user.user_name,
                              admin: user.user_admin }.to_json
    AuthCache.expire auth_key, 3600
    response.headers['X-AUTH-TOKEN'] = auth_key
    status 200
  end

  #  DELETE /session
  #
  #  Deletes an user session
  delete '/session/?' do
    user = UserModel.filter(auth_key: env['HTTP_X_AUTH_TOKEN']).first
    halt 403 if user.nil?
    session = AuthCache.get(user.auth_key)
    halt 403 if session.nil?
    AuthCache.del env['HTTP_X_AUTH_TOKEN']
    user.auth_key = nil
    user.save
    status 200
  end

  #  POST /users
  #  
  #  Create a users
  post '/users/?' do
    halt 403 unless env[:current_user][:admin]
    user = JSON.parse(request.body.read, symbolize_names: true)
    existing_user = UserModel.filter(user_name: user[:user_name]).first
    unless existing_user.nil?
      response.headers['Location'] = url("/users/#{existing_user[:user_id]}")
      halt 303
    end
    user[:client_id] = env[:current_user][:client_id] unless env[:current_user][:admin]
    user[:user_salt] = (0...8).map { (65 + rand(26)).chr }.join
    user[:user_password] = Digest::SHA2.hexdigest(user[:user_salt] + user[:user_password])
    user[:user_id] = SecureRandom.uuid
    UserModel.insert(user)
    user.to_json
  end

  #  GET /users
  #
  #  Fetch all users
  get '/users/?' do
    filters = { client_id: env[:current_user][:client_id] }
    filters = {} if env[:current_user][:admin]
    UserModel.filter(filters).all.map(&:to_hash).to_json
  end

  #  GET /users/:user
  #
  # Fetch a user byt its ID
  get '/users/:user/?' do
    if env[:current_user][:admin].nil?
      response.headers['Location'] = url("/users/#{existing_user[:user_id]}")
      halt 303
    end
    user = UserModel.filter(user_id: params[:user]).first
    halt 404 if user.nil?
    status 200
    return { user_id:    user[:user_id],
             client_id:  user[:client_id],
             user_name:  user[:user_name],
             user_email: user[:user_email],
             user_admin: user[:user_admin] }.to_json
  end

  #  PUT /users/:user
  #
  #  Updates a user by its ID
  put '/users/:user/?' do
    if env[:current_user][:admin]
      user = UserModel.filter(user_id: params[:user]).first
    else
      user = UserModel.filter(client_id: env[:current_user][:client_id],
                              user_id: params[:user]).first
    end
    halt 404 if user.nil?
    payload = JSON.parse(request.body.read, symbolize_names: true)
    unless env[:current_user][:admin]
      if payload.to_hash.key?(:old_password)
        old = Digest::SHA2.hexdigest(user[:user_salt] + payload[:old_password])
        halt 401 if old != user[:user_password]
      else
        halt 401
      end
    end
    if payload.to_hash.key?(:new_password)
      p = Digest::SHA2.hexdigest(user[:user_salt] + payload[:new_password])
      user[:user_password] = p if payload[:new_password]
    end
    user.save
    status 200
  end

  #  DELETE /users/:user
  #
  #  Deletes an user by its ID
  delete '/users/:user/?' do
    halt 403 unless env[:current_user][:admin]
    user = UserModel.filter(user_id: params[:user]).first
    halt 404 if user.nil?
    halt 403 if user[:user_admin]
    user.delete
    status 200
  end
end
