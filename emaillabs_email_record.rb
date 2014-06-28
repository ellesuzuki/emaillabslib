## Copyright 2008 Elle Yoko Suzuki
## This EmailLabs Automation Library program is distributed under the terms of the GNU 
## General Public License.
##
## This file is part of EmailLabs Automation Library.
##
## EmailLabs Automation Library is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## EmailLabs Automation Library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with EmailLabs Automation Library.  If not, see <http://www.gnu.org/licenses/>.



class Emaillabs::EmaillabsEmailRecord

  attr_accessor :email,
                :info_in,
                :info_out,
                :activity,
                :xml_post,
                :resp_type,
                :resp_record,
                :resp_data

  require 'net/http'
  require 'uri'
  require 'rexml/document'
  require 'net/smtp'

  require 'emaillabs/emaillabs_xml_post'
  require 'emaillabs/emaillabs_helpers'


  ##----- EmailRecord class methods to use ----- //
  def initialize(email = '')
    @email = email    # required!  validate address format
    @info_in = {}    # check is hash
    @activity = ''
  end

  def exists?
    @activity = 'query-data'
    get_record

    if @resp_type == 'success' or @resp_data[0] == "Email address already exists"  # from .get_record
      true
    elsif @resp_data[0] == "Unauthorized"
      error_msg = "http response #{@resp_data[0]} in Emaillabs::EmaillabsEmailRecord exists? method.\n"
      error_msg += "check api domains.\n"
      error_msg += "add address #{@email} to MLID #{EmaillabsHelpers::MLID} manually.\n"
      error_msg += "add info #{@info_in} manually." if !@info_in.empty?
      EmaillabsHelpers::send_msg(error_msg)
      raise EmaillabsHelpers::HttpError.new, caller   # caller should abort
    else
      false
    end
  end
  
  def subscribed?
    @activity = 'query-data'

    if exists?
      (@xml_post.root.elements["RECORD/DATA[@id='state']"].text == 'active') ? true : false
    else
      false
    end
  end

  def subscribe
    if !subscribed?
      if exists?
        @activity = 'update' # subscribed sets @activity to 'query-data'
        @info_in['state'] = 'active'
      elsif !exists?
        @activity = 'add'
      end

      build_demographics
      send_record
    end
  end

  def unsubscribe
    if subscribed?
      state = 'unsubscribed'
      @activity = 'update'
      @info_out = "<DATA type='extra' id='state'>#{state}</DATA>"

      send_record
    end
  end

  def add_info(info)
    if exists? # email record must first be created before info can be added
      @activity = 'update'
      @info_in = info # eg, {'First Name' => 'elizabeth', 'Last Name' => 'zimmerman', 'Shipping Zip' => '94710'}
      build_demographics
      send_record
    end
  end


  ##----- EmailRecord class helper methods ----- //
  def get_record
    begin
    @xml_post = Emaillabs::EmaillabsXmlPost.new(@email, @info_in, @activity)  # @info_in empty hash for query methods

    @xml_post.construct
    @xml_post.post
    @xml_post.parse

    # prep results from .parse for use by primary methods
    @resp_type = ''
    @xml_post.root.elements.each('TYPE') { |e| @resp_type = e.text }

    @resp_record = ''
    @xml_post.root.elements.each('RECORD') { |e| @resp_record = e }

    @resp_data = []
    @xml_post.root.elements.each('DATA') { |e| @resp_data.push(e.text) }  # list of items unless just feedback from adding new record successfully
    end
  end
  
  def send_record
    @xml_post = Emaillabs::EmaillabsXmlPost.new(@email, @info_out, @activity)

    @xml_post.construct
    @xml_post.post

    # TODO: make sure the result was a success, and handle accordingly if was not
  end

  def build_demographics
    @info_out = ''
    
    if !@info_in.empty?
      for each_demog in @info_in.keys # might have one pair, or more pairs; eg, {'First Name' => 'ruby', 'Last Name' => 'smith'}
        if EmaillabsHelpers::DATA_TYPE_DEMOG.keys.include?(each_demog)
          data_type = 'demographic'
          data_id = EmaillabsHelpers::DATA_TYPE_DEMOG[each_demog]
          data_val = @info_in[each_demog]
        elsif EmaillabsHelpers::DATA_TYPE_EXTRA.include?(each_demog) # an array, not a hash
          data_type = 'extra'
          data_id = each_demog
          data_val = @info_in[each_demog]
        end

        @info_out += "<DATA type='"+"#{data_type}"+"'"+" id='"+"#{data_id}"+"'"+">#{data_val}</DATA>"
      end
    end
  end
  
end