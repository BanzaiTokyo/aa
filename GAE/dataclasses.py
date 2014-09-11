from google.appengine.ext import ndb

class Question(ndb.Model):
   question   = ndb.TextProperty(indexed=False)
   askedby    = ndb.KeyProperty(kind='User')
   askedon    = ndb.DateTimeProperty(auto_now_add=True)
   queue      = ndb.IntegerProperty(default=0) #ex. numanswers
   numassigns = ndb.IntegerProperty(default=0)
   numanswers = ndb.IntegerProperty(indexed=False, default=0)
   lastanswer = ndb.DateTimeProperty()

class Refused(ndb.Model): #questions that user don't want to answer
   refusedby  = ndb.KeyProperty(kind='User')
   question   = ndb.KeyProperty(kind='Question')
   reason     = ndb.StringProperty(indexed=False)

class AssignedQuestion(ndb.Model):
   question   = ndb.KeyProperty(kind='Question', indexed=False)
   status     = ndb.StringProperty(indexed=False)

class Answer(ndb.Model):
   answer     = ndb.TextProperty(indexed=False)
   answeredby = ndb.KeyProperty(kind='User')
   answeredon = ndb.DateTimeProperty(auto_now_add=True)
   question   = ndb.KeyProperty(kind='Question') # back reference to Question
   helpful    = ndb.IntegerProperty(indexed=False, default=0) # rating fields
   detailed   = ndb.IntegerProperty(indexed=False, default=0)
   funny      = ndb.IntegerProperty(indexed=False, default=0)
   rated      = ndb.IntegerProperty(indexed=False, default=0)

class User(ndb.Model):
   nickname          = ndb.StringProperty(indexed=False)
   password          = ndb.StringProperty(indexed=False)
   points            = ndb.IntegerProperty(indexed=False, default=0)
   assignedquestions = ndb.StructuredProperty(AssignedQuestion, repeated=True, indexed=False)
   assignedon = ndb.DateTimeProperty(indexed=False)
   deviceidentifier  = ndb.StringProperty()
   devicetoken       = ndb.StringProperty(indexed=False)

class ApnConfig(ndb.Model):
    gcm_api_key = ndb.StringProperty()
    gcm_multicast_limit = ndb.IntegerProperty()
    apns_multicast_limit = ndb.IntegerProperty()
    apns_test_mode = ndb.BooleanProperty()
    apns_sandbox_cert = ndb.TextProperty()
    apns_sandbox_key = ndb.TextProperty()
    apns_cert = ndb.TextProperty()
    apns_key = ndb.TextProperty()
