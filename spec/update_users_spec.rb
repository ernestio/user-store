# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require File.expand_path '../spec_helper.rb', __FILE__

describe 'updating users' do
  describe 'a non authorized access' do
    describe 'tries to update an user' do
      it 'should throw HTTP 403 error code' do
        put '/users'
        expect(last_response.status).to be 403
      end
    end
  end

  describe 'an authorized access' do
    describe 'tries to update an user' do
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

      describe 'update a different user being not admin' do
        before do
          user = UserModel.new
          user.user_id = '6E875930-1B26-4CAA-952C-7AA2CDFE2D97'
          user.client_id = 'fake_client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_admin = false
          user.user_salt = 'xx'
          user.user_password = Digest::SHA2.hexdigest(user.user_salt + 'fakepass')
          user.save
          updated_user = {
            old_password: 'foobar',
            user_password: 'newpass'
          }
          put '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
              updated_user.to_json,
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 404' do
          expect(last_response.status).to be 404
        end
      end

      describe 'update user without sending old password' do
        before do
          user = UserModel.new
          user.user_id = '6E875930-1B26-4CAA-952C-7AA2CDFE2D97'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = false
          user.user_salt = 'xx'
          user.save
          updated_user = {
            user_id: user.user_id,
            client_id: user.client_id,
            user_name: user.user_name,
            user_email: user.user_email,
            user_passwod: 'newpass',
            user_admin: user.user_admin,
            user_salt: user.user_salt
          }
          put '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
              updated_user.to_json,
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 401' do
          expect(last_response.status).to be 401
        end
      end

      describe 'update user sending and incorrect old password' do
        before do
          user = UserModel.new
          user.user_id = '6E875930-1B26-4CAA-952C-7AA2CDFE2D97'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_admin = false
          user.user_salt = 'xx'
          user.user_password = Digest::SHA2.hexdigest(user.user_salt + 'fakepass')
          user.save
          updated_user = {
            old_password: 'foobar',
            user_password: 'newpass'
          }
          put '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
              updated_user.to_json,
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 401' do
          expect(last_response.status).to be 401
        end
      end

      describe 'update user sending old password' do
        before do
          user = UserModel.new
          user.user_id = '6E875930-1B26-4CAA-952C-7AA2CDFE2D97'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_admin = false
          user.user_salt = 'xx'
          user.user_password = Digest::SHA2.hexdigest(user.user_salt + 'fakepass')
          user.save
          updated_user = {
            old_password: 'fakepass',
            user_password: 'newpass'
          }
          put '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
              updated_user.to_json,
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 200' do
          expect(last_response.status).to be 200
        end
        it 'the user should update the password as we provide old password on the payload' do
          user = UserModel.dataset.filter(user_name: 'username').first.to_hash
          expect(user[:user_password]).to eq('40c7f8003833737b6d4be70dea8816868e69dfab1bdae543f68ce23e10149477')
        end
      end
    end
  end

  describe 'an authorized admin access' do
    describe 'tries to update an user' do
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
      it 'should have a valid auth token' do
        expect(@token).to_not be_nil
      end

      describe 'update user' do
        before do
          user = UserModel.new
          user.user_id = '6E875930-1B26-4CAA-952C-7AA2CDFE2D97'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = false
          user.user_salt = 'xx'
          user.save
          updated_user = {
            user_id: user.user_id,
            client_id: user.client_id,
            user_name: user.user_name,
            user_email: 'changed@example.org',
            user_passwod: user.user_password,
            user_admin: user.user_admin,
            user_salt: user.user_salt
          }
          put '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
              updated_user.to_json,
              'HTTP_X_AUTH_TOKEN' => @token,
              'CONTENT_TYPE' => 'application/json'
        end
        it 'should throw HTTP 200 code' do
          expect(last_response.status).to be 200
        end
      end

      describe 'update a non existing user' do
        updated_user = {
          user_id: 'fakeuserid',
          client_id: 'client_id',
          user_name: 'fake',
          user_email: 'fake@example.og',
          user_passwod: 'fakepass',
          user_admin: false
        }
        before do
          put '/users/fakeuserid',
              updated_user.to_json,
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
