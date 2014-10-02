from google.appengine.ext import ndb

class Question(ndb.Model):
   question   = ndb.TextProperty(indexed=False)
   askedby    = ndb.KeyProperty(kind='User')
   askedon    = ndb.DateTimeProperty(auto_now_add=True)
   queue      = ndb.IntegerProperty(default=0) #ex. numanswers
   numassigns = ndb.IntegerProperty(default=0)
   numanswers = ndb.IntegerProperty(indexed=False, default=0)
   lastanswer = ndb.DateTimeProperty()
   moderated  = ndb.IntegerProperty(default=0) #0 - not moderated yet, 1 - approved, -1 - rejected

class Refused(ndb.Model): #questions that user don't want to answer
   refusedby  = ndb.KeyProperty(kind='User')
   question   = ndb.KeyProperty(kind='Question')
   reason     = ndb.StringProperty(indexed=False)

class AssignedQuestion(ndb.Model):
   question   = ndb.KeyProperty(kind='Question', indexed=False)
   status     = ndb.StringProperty(indexed=False) #possible statuses: new, in review, approved, banned

class Answer(ndb.Model):
   answer     = ndb.TextProperty(indexed=False)
   answeredby = ndb.KeyProperty(kind='User')
   answeredon = ndb.DateTimeProperty(auto_now_add=True)
   question   = ndb.KeyProperty(kind='Question') # back reference to Question
   helpful    = ndb.IntegerProperty(indexed=False, default=0) # rating fields
   detailed   = ndb.IntegerProperty(indexed=False, default=0)
   funny      = ndb.IntegerProperty(indexed=False, default=0)
   rated      = ndb.IntegerProperty(indexed=False, default=0)
   moderated  = ndb.IntegerProperty(default=0) #0 - not moderated yet, 1 - approved, -1 - rejected

class User(ndb.Model):
   nickname          = ndb.StringProperty(indexed=False)
   password          = ndb.StringProperty(indexed=False)
   points            = ndb.IntegerProperty(indexed=False, default=0)
   assignedquestions = ndb.StructuredProperty(AssignedQuestion, repeated=True, indexed=False)
   assignedon        = ndb.DateTimeProperty(indexed=False)
   deviceidentifier  = ndb.StringProperty()
   devicetoken       = ndb.StringProperty(indexed=False)
   email             = ndb.StringProperty()
   registeredon      = ndb.DateTimeProperty(auto_now_add=True, indexed=False)
   lastvisit         = ndb.DateTimeProperty(indexed=False)
   #can_answer = False - some of assigned questions are "new" or "in review" or not rated by the asker.
   #User is not allowed to refresh question list
   can_answer        = ndb.BooleanProperty(indexed=False, default=True)

class ApnConfig(ndb.Model):
   gcm_api_key = ndb.StringProperty(indexed=False)
   gcm_multicast_limit = ndb.IntegerProperty(indexed=False)
   apns_multicast_limit = ndb.IntegerProperty(indexed=False)
   apns_test_mode = ndb.BooleanProperty(indexed=False)
   apns_sandbox_cert = ndb.TextProperty(indexed=False)
   apns_sandbox_key = ndb.TextProperty(indexed=False)
   apns_cert = ndb.TextProperty(indexed=False)
   apns_key = ndb.TextProperty(indexed=False)
   admin_devices = ndb.TextProperty(indexed=False)
   apns_admin_cert = ndb.TextProperty(indexed=False)
   apns_admin_key = ndb.TextProperty(indexed=False)
