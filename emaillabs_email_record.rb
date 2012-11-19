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

  attr_accessor :email, :info_in, :info_out, :activity, :xml_post, :resp_type, :resp_record, :resp_data

  require 'net/http'
  require 'uri'
  require 'rexml/document'
  require 'net/smtp'

  require 'emaillabs/emaillabs_xml_post'
  require 'emaillabs/emaillabs_helpers'


  ##----- EmailRecord class methods to use ----- //
  def initialize(email='')
    @email = email    # required!  validate address format
    @info_in = {}    # check is hash
    @activity = ''
  end

  ## find out if a record for the email address already exists in emaillabs
  def exists?
    @activity = 'query-data'
    ## call get_record, and should be able to simply find out if exists
    get_record()
    if @resp_type == 'success' or @resp_data[0] == "Email address already exists"  # from .get_record
      return true
    elsif @resp_data[0] == "Unauthorized"
      error_msg = "http response #{@resp_data[0]} in Emaillabs::EmaillabsEmailRecord exists? method.\n"
      error_msg += "check api domains.\n"
      error_msg += "add address #{@email} to MLID #{EmaillabsHelpers::MLID} manually.\n"
      error_msg += "add info #{@info_in} manually." if @info_in != ''
      EmaillabsHelpers::send_msg(error_msg)
      raise EmaillabsHelpers::HttpError.new(), caller   # caller should abort
    else
      return false
    end
  end
  
  ## find out if the email address is set as 'active' (subscribed) if in emaillabs
  def is_subscribed?
    @activity = 'query-data'

    if exists? == true
      if @xml_post.root.elements["RECORD/DATA[@id='state']"].text == 'active'    # from .parse
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def subscribe()
    if is_subscribed? == false
      if exists?
        @activity = 'update' #since exists and is_subscribed sets @activity to 'query-data'
        @info_in['state'] = 'active'
      elsif exists? != true
        @activity = 'add'
      end
      build_demographics
      send_record
    #do nothing if is_subscribed? == true
    end
  end

  ## change record's state associated with email address to 'unsubscribed' if address is currently set to 'active' (aka, subscribed)
  def unsubscribe()
    if is_subscribed? == true
      state = 'unsubscribed'
      @activity = 'update'
      @info_out = "<DATA type='extra' id='state'>#{state}</DATA>"

      send_record
    end
    #do nothing if not even subscribed to begin with.  note, this is not the same thing as 'does not exist'.
  end

  def add_info(info) # info is a hash
    if exists?
      @activity = 'update'
      @info_in = info # might be {'First Name' => 'elizabeth','Last Name' => 'zimmerman','Shipping Zip' => '94710'}
      build_demographics
      send_record
    ## no sense adding info to a record that does not yet exist.  email record must first be created.
    end
  end


  ##----- EmailRecord class helper methods ----- //
  ## used by querying, non-altering methods only: exists?, is_subscribed?
  def get_record()
    begin
    @xml_post = Emaillabs::EmaillabsXmlPost.new(@email, @info_in, @activity)  # @info_in empty hash for query methods

    @xml_post.construct
    @xml_post.post
    @xml_post.parse

    # prep results from .parse for use by main primary methods
    @resp_type = ''
    @xml_post.root.elements.each('TYPE') { |e| @resp_type = e.text }

    @resp_record =''
    @xml_post.root.elements.each('RECORD') { |e| @resp_record = e }

    @resp_data = []
    @xml_post.root.elements.each('DATA') { |e| @resp_data.push(e.text) }  # list of items unless just feedback from adding new record successfully
    end
  end
  
  ## used by methods that alter: update, add, unsubscribe
  def send_record()
    @xml_post = Emaillabs::EmaillabsXmlPost.new(@email,@info_out,@activity)

    @xml_post.construct
    @xml_post.post
    # include making sure the result was a success, and handle accordingly if was not
  end

  ## helper method
  def build_demographics()
    @info_out = ''
    
    if !@info_in.empty?
      for each_demog in @info_in.keys # might have one pair, or more pairs; eg, {'First Name' => 'ruby','Last Name' => 'smith'}
        if EmaillabsHelpers::DATA_TYPE_DEMOG.keys.include?(each_demog)
          data_type = 'demographic'
          data_id = EmaillabsHelpers::DATA_TYPE_DEMOG[each_demog]
          data_val = @info_in[each_demog]
        elsif EmaillabsHelpers::DATA_TYPE_EXTRA.include?(each_demog) #an array, not a hash
          data_type = 'extra'
          data_id = each_demog
          data_val = @info_in[each_demog]
        end
      @info_out += "<DATA type='"+"#{data_type}"+"'"+" id='"+"#{data_id}"+"'"+">#{data_val}</DATA>"
      end # for
    end # if
    
  end
  
end
