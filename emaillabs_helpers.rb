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



## this is the emaillabs parent class
module EmaillabsHelpers
    require 'net/http'
    require 'uri'
    require 'rexml/document'
    require 'net/smtp'


    ##----- BEGIN CONSTANTS ----- //

    #uncomment and set your company's ID with emaillabs
    #SITE_ID =

    #uncomment and set your client's mailing list ID
    #MLID =


    TYPE = 'record'

    #uncomment and set your company's URL with emaillabs, eg, 'www.elabs7.com'
    #EMAILLABS_URL = ''
    #
    #uncomment and set your emaillabs path, eg, '/API/mailing_list.html'
    #EMAILLABS_PATH = ''
    #
    # demographics with corresponding codes, check emaillabs account for more codes as needed
    # some possible demographics with example codes: First name => '1', 'Company Name' => '14', etc.
    DATA_TYPE_DEMOG = {
                      'First Name' => '',
                      'Last Name' => '',
                      'Source IP Address' => '',
                      'Date Subscribed' => '',
                      'Billing Address 1' => '',
                      'Billing Address 2' => '',
                      'Billing City' => '',
                      'Billing Zip' => '',
                      'Billing State' => '',
                      'Shipping Zip' => '',
                      'Shipping Address 1' => '',
                      'Shipping Address 2' => '',
                      'Shipping City' => '',
                      'Shipping State' => '',
                      'Shipping First Name' => '',
                      'Shipping Last Name' => '',
                      'State Code' => '', 'Phone' => '', 'Country' => '', 'Title' => '',
                      'Company Name' => '', 'Home Town' => ''
                      }

    # add extra demographics as needed; eg, DATA_TYPE_EXTRA = ['state']

    #uncomment and set email addresses for error reporting
    #MSG_TO_ADDR = 'admin@yourcompany.com'
    #MSG_FR_ADDR = 'admin@yourcompany.com'
    #
    ##----- END CONSTANTS ----- //


    ## custom exception(s)
    class HttpError < StandardError
      def initialize
      end
    end


    ##----- misc useful functions for emaillabs ----- //

    ## send email if errors arise
    def EmaillabsHelpers.send_msg(error_msg)
    msg=<<EOF
    Subject: EmailLabs problem for Mail List ID##{MLID}\n
    oops!  there seems to be a problem..\n
    #{error_msg}
EOF

      Net::SMTP.start('localhost') do |smtp|
        smtp.send_message(msg, MSG_FR_ADDR, MSG_TO_ADDR)
        smtp.finish
      end
    end


    ## set up custom error handling as desired
    def EmaillabsHelpers.handle_exceptions(error_msg)
      rescue SocketError, HttpError # post/parse problems
        abort
      rescue EOFError

      rescue Exception => e         # generic rescue for everything else
        message = error_msg
        send_msg(message)
      end
    end

    
    # set up email format checking here, else will have lots of garbage in the emaillabs site;
    def EmaillabsHelpers.valid_email_format?(email_addr)
      # 1 or more of A-Za-z0-9_-, followed by 1 '@', followed by one or more groupings of at least 1 A-Za-z0-9_- and a dot, followed by 2 or 3 alphabet letters
      format_regex = Regexp.new('[\w\.-]+[@]{1}([\w-]+\.{1})+[A-Za-z]{2,3}') # at least 'a@a.aa', or 'a@a.a.aa'
      email_addr =~ format_regex ? true : false
    end
  
end