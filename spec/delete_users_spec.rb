# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require File.expand_path '../spec_helper.rb', __FILE__

describe 'deleting users' do
  describe 'a non authorized access' do
    describe 'tries to delete an user' do
      it 'should throw a 403' do
        delete '/users/id'
        expect(last_response.status).to be 403
      end
    end
  end

  describe 'an authorized access' do
    describe 'tries to delete an user' do
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

      describe 'delete user' do
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
          delete '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
                 {},
                 'HTTP_X_AUTH_TOKEN' => @token,
                 'CONTENT_TYPE' => 'application/json'
        end
        it 'should response with HTTP 403' do
          expect(last_response.status).to be 403
        end
      end
    end
  end

  describe 'an authorized admin access' do
    describe 'tries to delete an user' do
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

      describe 'delete user' do
        before do
          user = UserModel.new
          user.user_id = '6E875930-1B26-4CAA-952C-7AA2CDFE2D97'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = false
          user.user_salt = 'x'
          user.save
          delete '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
                 {},
                 'HTTP_X_AUTH_TOKEN' => @token,
                 'CONTENT_TYPE' => 'application/json'
        end
        it 'should response with HTTP 200' do
          expect(last_response.status).to be 200
        end
      end

      describe 'delete admin user' do
        before do
          user = UserModel.new
          user.user_id = '6E875930-1B26-4CAA-952C-7AA2CDFE2D97'
          user.client_id = 'client_id'
          user.user_name = 'username'
          user.user_email = 'username@example.org'
          user.user_password = 'fakepass'
          user.user_admin = true
          user.user_salt = 'x'
          user.save
          delete '/users/6E875930-1B26-4CAA-952C-7AA2CDFE2D97',
                 {},
                 'HTTP_X_AUTH_TOKEN' => @token,
                 'CONTENT_TYPE' => 'application/json'
        end
        it 'should response with HTTP 403' do
          expect(last_response.status).to be 403
        end
      end

      describe 'delete a non existing user' do
        before do
          delete '/users/fakeuserid',
                 {},
                 'HTTP_X_AUTH_TOKEN' => @token,
                 'CONTENT_TYPE' => 'application/json'
        end
        it 'should response with HTTP 404' do
          expect(last_response.status).to be 404
        end
      end
    end
  end
end
