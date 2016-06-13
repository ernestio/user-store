# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require File.expand_path '../spec_helper.rb', __FILE__

describe 'getting users' do
  describe 'a non authorized access' do
    describe 'get all users' do
      it 'should throw HTTP 403 error code' do
        get '/users'
        expect(last_response.status).to be 403
      end
    end
    describe 'get an user' do
      it 'should throw HTTP 403 error code' do
        get '/users/id'
        expect(last_response.status).to be 403
      end
    end
  end

  describe 'an authorized access' do
    let!(:user_id)        { SecureRandom.uuid }
    let!(:client_id)      { 'client_id' }
    let!(:user_name)      { 'username' }
    let!(:user_password)  { 'password' }
    before do
      UserModel.dataset.destroy
      @token = SecureRandom.hex
      AuthCache.set @token, { user_id: user_id,
                              client_id: client_id,
                              user_name: user_name,
                              admin: false }.to_json
      AuthCache.expire @token, 3600
    end
    it 'should have a valid auth token' do
      expect(@token).to_not be_nil
    end

    describe 'tries to get all users' do
      before do
        1.upto(10) do |i|
          user = UserModel.new
          user.user_id = SecureRandom.uuid
          user.client_id = 'client_id'
          user.user_name = 'username' + i.to_s
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = false
          user.user_salt = 'xx'
          user.save
        end
        get '/users',
            {},
            'HTTP_X_AUTH_TOKEN' => @token,
            'CONTENT_TYPE' => 'application/json'
      end
      it 'should throw HTTP 200 code' do
        expect(last_response.status).to be 200
      end
      it 'should return a list of existing users' do
        expect(JSON.parse(last_response.body).length).to be(10)
      end
    end

    describe 'tries to get an user' do
      describe 'get existing user' do
        before do
          user = UserModel.new
          user.user_id = 'B85C5C1D-4F33-483B-9ACD-1A88779CD30E'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = false
          user.user_salt = 'xx'
          user.save
          get '/users/B85C5C1D-4F33-483B-9ACD-1A88779CD30E',
              {},
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 200 code' do
          expect(last_response.status).to be 200
        end
      end

      describe 'get non existing user' do
        before do
          get '/users/fakeid',
              {},
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 404 error code' do
          expect(last_response.status).to be 404
        end
      end
    end
  end

  describe 'an authorized admin access' do
    let!(:user_id)        { SecureRandom.uuid }
    let!(:client_id)      { 'client_id' }
    let!(:user_name)      { 'username' }
    let!(:user_password)  { 'password' }
    before do
      UserModel.dataset.destroy
      @token = SecureRandom.hex
      AuthCache.set @token, { user_id: user_id,
                              client_id: client_id,
                              user_name: user_name,
                              admin: false }.to_json
      AuthCache.expire @token, 3600
    end
    it 'should have a valid auth token' do
      expect(@token).to_not be_nil
    end

    describe 'tries to get all users' do
      before do
        1.upto(10) do |i|
          user = UserModel.new
          user.user_id = SecureRandom.uuid
          user.client_id = 'client_id'
          user.user_name = 'username' + i.to_s
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = false
          user.user_salt = 'xx'
          user.save
        end
        get '/users',
            {},
            'HTTP_X_AUTH_TOKEN' => @token,
            'CONTENT_TYPE' => 'application/json'
      end
      it 'should throw HTTP 200 code' do
        expect(last_response.status).to be 200
      end
      it 'should return a list of existing users' do
        expect(JSON.parse(last_response.body).length).to be(10)
      end
    end

    describe 'tries to get an user' do
      describe 'get existing user' do
        before do
          user = UserModel.new
          user.user_id = 'B85C5C1D-4F33-483B-9ACD-1A88779CD30E'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = false
          user.user_salt = 'xx'
          user.save
          get '/users/B85C5C1D-4F33-483B-9ACD-1A88779CD30E',
              {},
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 200 code' do
          expect(last_response.status).to be 200
        end
      end

      describe 'get non existing user' do
        before do
          get '/users/fakeid',
              {},
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 404 error code' do
          expect(last_response.status).to be 404
        end
      end
    end
  end
end
