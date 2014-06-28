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



class Emaillabs::EmaillabsXmlPost
  
  attr_reader   :email  # no reason to change this!
  attr_accessor :info_out,
                :activity,
                :xml_request,
                :http_resp,
                :doc,
                :root

  require 'emaillabs/emaillabs_helpers'


  ## for xmlpost = XmlPost.new(email,other,activity)
  ## instantiate an xmlpost object for use by EmailRecord methods
  def initialize(email, info, activity)
    @email = email  # required!  validate method
    @info_out = info
    @activity = activity
  end

  def construct
    # @info_out is empty for emaillabs class query methods
    @xml_request = "<DATASET><SITE_ID>#{EmaillabsHelpers::SITE_ID}</SITE_ID><MLID>#{EmaillabsHelpers::MLID}</MLID><DATA type='email'>#{@email}</DATA>#{@info_out}</DATASET>"
  end
  
  ## prepare xml results for quick reading by primary functions
  def post
    begin
    @http_resp = Net::HTTP.start(EmaillabsHelpers::EMAILLABS_URL) do |http|
      http.post(EmaillabsHelpers::EMAILLABS_PATH, "type=#{EmaillabsHelpers::TYPE}&activity=#{@activity}&input=" + URI.escape(@xml_request))
    end

    rescue SocketError  # a domain does not exist or emaillabs farm server is down
      error_msg = "emaillabs server may be down, or domain does not exist.\n"
      error_msg += "problem talking with url in Emaillabs::XmlPost post method.\n"
      error_msg += "add address #{@email} to MLID #{EmaillabsHelpers::MLID} manually.\n"
      error_msg += "add info #{@info_out} manually." if !@info_out.empty?
      EmaillabsHelpers::send_msg(error_msg)
      raise SocketError
    end

    if @http_resp.class != Net::HTTPOK
      error_msg = "http response (@http_resp) in Emaillabs::XmlPost post method returned a #{http_resp.class}.\n"
      error_msg += "check domain, server valid?\n"
      error_msg += "add address #{@email} to MLID #{EmaillabsHelpers::MLID} manually.\n"
      error_msg += "add info #{@info_out} manually." if !@info_out.empty?
      EmaillabsHelpers::send_msg(error_msg)
      raise EmaillabsHelpers::HttpError.new, caller       #caller should abort
    end
  end
  
  def parse
    @doc = REXML::Document.new(@http_resp.body)
    @root = doc.root  # with(in) <DATASET> only ?
  end

end
