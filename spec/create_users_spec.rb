# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require File.expand_path '../spec_helper.rb', __FILE__

describe 'creating users' do
  describe 'a non authorized access' do
    describe 'tries to create an user' do
      it 'should throw a 403' do
        post '/users'
        expect(last_response.status).to be 403
      end
    end
  end

  describe 'an authorized access' do
    describe 'tries to create an user' do
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
      it 'should get a valid token' do
        expect(@token).to_not be_nil
      end
      describe 'create user' do
        before do
          user = {
            user_id: '6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
            client_id: 'client_id',
            user_name: 'username',
            user_email: 'username@example.org',
            user_password: 'fakepass',
            user_admin: false
          }
          post '/users',
               user.to_json,
               'HTTP_X_AUTH_TOKEN' => @token,
               'CONTENT_TYPE' => 'application/json'
        end
        it 'should respond with a 403 code' do
          expect(last_response.status).to be 403
        end
      end
    end
  end

  describe 'an authorized admin access' do
    describe 'tries to create an user' do
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
                                admin: true }.to_json
        AuthCache.expire @token, 3600
      end
      it 'should get a valid token' do
        expect(@token).to_not be_nil
      end

      describe 'create user' do
        before do
          user = {
            user_id: SecureRandom.uuid,
            client_id: 'client_id',
            user_name: 'username',
            user_email: 'username@example.org',
            user_password: 'fakepass',
            user_admin: false
          }
          post '/users',
               user.to_json,
               'HTTP_X_AUTH_TOKEN' => @token,
               'CONTENT_TYPE' => 'application/json'
        end
        it 'should respond with a 200 code' do
          expect(last_response.status).to be 200
        end
        it 'should store the object on the database' do
          users = UserModel.dataset.filter(user_name: 'username')
          expect(users.count).to be(1)
        end
      end

      describe 'create duplicated user' do
        before do
          user = {
            user_id: '6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
            client_id: 'client_id',
            user_name: 'username',
            user_email: 'username@example.org',
            user_password: 'fakepass',
            user_admin: false
          }
          post '/users',
               user.to_json,
               'HTTP_X_AUTH_TOKEN' => @token,
               'CONTENT_TYPE' => 'application/json'
          post '/users',
               user.to_json,
               'HTTP_X_AUTH_TOKEN' => @token,
               'CONTENT_TYPE' => 'application/json'
        end
        it 'should respond with a HTTP 303 code' do
          expect(last_response.status).to be 303
        end
      end
    end
  end
end
