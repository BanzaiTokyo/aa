#!/usr/bin/env python
# appengine-apns-gcm was developed by Garett Rogers <garett.rogers@gmail.com>
# Source available at https://github.com/GarettRogers/appengine-apns-gcm
#
# appengine-apns-gcm is distributed under the terms of the MIT license.
#
# Copyright (c) 2013 AimX Labs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from apns import *
from dataclasses import ApnConfig

def convertToApnsMessage(self, message):
    apnsmessage = {}
    apnsmessage["data"] = {}
    apnsmessage["sound"] = "default"
    apnsmessage["badge"] = -1
    apnsmessage["alert"] = None
    apnsmessage["custom"] = None
    
    if 'ios_sound' in message["request"]:
        apnsmessage["sound"] = message["request"]["ios_sound"]
    
    if 'data' in message["request"]:
        apnsmessage["custom"] = message["request"]["data"]

    if 'ios_badge' in message["request"]:
        apnsmessage["badge"] = message["request"]["ios_badge"]

    if 'ios_message' in message["request"] and 'ios_button_text' in message["request"]:
        apnsmessage["alert"] = PayloadAlert(message["request"]["ios_message"], action_loc_key=message["request"]["ios_button_text"])
    else:
        if 'ios_message' in message["request"]:
            apnsmessage["alert"] = message["request"]["ios_message"]
    
    return apnsmessage

def getAPNs(admin_app):
    appconfig = ApnConfig.get_or_insert("config")

    if admin_app:
        return APNs(use_sandbox=True, cert_file=appconfig.apns_admin_cert, key_file=appconfig.apns_admin_key)
    elif appconfig.apns_test_mode:
        return APNs(use_sandbox=True, cert_file=appconfig.apns_sandbox_cert, key_file=appconfig.apns_sandbox_key)
    else:
        return APNs(use_sandbox=False, cert_file=appconfig.apns_cert, key_file=appconfig.apns_key)

def sendMulticastApnsMessage(self, apns_reg_ids, apnsmessage, admin_app):
    apns = getAPNs(admin_app)
    
    # Send a notification
    payload = Payload(alert=apnsmessage["alert"], sound=apnsmessage["sound"], custom=apnsmessage["custom"], badge=apnsmessage["badge"])
    apns.gateway_server.send_notifications(apns_reg_ids, payload)

    # Get feedback messages
    for (token_hex, fail_time) in apns.feedback_server.items():
        break

def sendSingleApnsMessage(self, message, token):
    apns_reg_ids=[token]
    sendMulticastApnsMessage(self, apns_reg_ids, message, False)


#Sample POST Data -->  platform=1&token=<device token string>&message={"request":{"data":{"custom": "json data"}, "ios_message":"This is a test","ios_button_text":"yeah!","ios_badge": -1, "ios_sound": "soundfile", "android_collapse_key": "collapsekey"}}
class SendPushMessage():
   def post(self, token, answerID, message):
      #Send a single message to a device token
      message = {'request': {'data': {'custom': answerID}, 'ios_message': 'You have a new answer', 'ios_badge': 1}}
      message = convertToApnsMessage(self, message)
      sendSingleApnsMessage(self, message, token)

   def post_for_admin(self, tokens, message):
    message = {'request': {'data': {'custom': 0}, 'ios_message': message, 'ios_badge': 1}}
    message = convertToApnsMessage(self, message)
    sendMulticastApnsMessage(self, tokens, message, True)
