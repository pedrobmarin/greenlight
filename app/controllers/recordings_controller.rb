# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>

class RecordingsController < ApplicationController
  layout false

  before_action :find_room
  before_action :verify_room_ownership, except: :play_recording

  META_LISTED = "gl-listed"

  # GET /:meetingID/:record_id/:format
  def play_recording
    @recording, @url = @room.play_recording(params[:record_id], params[:type])

    # If it is private, and it is not the owner, can't access recording
    redirect_to unauthorized_path if @room.owner != current_user &&
                                     @recording &&
                                     @recording[:metadata][:'gl-listed'] == 'private'

    @token_url = @room.token_url(@user,
      request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip,
      params[:record_id],
      @url)
  end

  # POST /:meetingID/:record_id
  def update_recording
    meta = {
      "meta_#{META_LISTED}" => params[:state],
    }

    res = @room.update_recording(params[:record_id], meta)

    # Redirects to the page that made the initial request
    redirect_to request.referrer if res[:updated]
  end

  # DELETE /:meetingID/:record_id
  def delete_recording
    @room.delete_recording(params[:record_id])

    # Redirects to the page that made the initial request
    redirect_to request.referrer
  end

  private

  def find_room
    @room = Room.find_by!(bbb_id: params[:meetingID])
  end

  # Ensure the user is logged into the room they are accessing.
  def verify_room_ownership
    redirect_to root_path unless @room.owned_by?(current_user)
  end
end
