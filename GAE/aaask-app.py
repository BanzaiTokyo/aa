import webapp2
import logging

from google.appengine.ext import ndb
import datetime
import json
from dataclasses import *

#constants
INITIAL_POINTS    = 4
POINTS_TO_ASK     = 3
POINTS_FOR_ANSWER = 1
QUESTIONS_NUMBER  = 3

from webapp2_extras import sessions
def authorized(fn):
   def wrapper(*args):
      args[0].user = None
      email = args[0].session.get('email')
      if email:
         user = User.query(User.email== email).fetch(1)
         if len(user):
            user = user[0]
            args[0].user = user
      else:
         deviceIdentifier = args[0].request.get('deviceIdentifier')
         if deviceIdentifier:
            user = User.query(User.deviceidentifier == deviceIdentifier).fetch(1)
            if len(user):
               user = user[0]
               args[0].user = user
            else:
               user = User()
               user.deviceidentifier = deviceIdentifier
               user.email = deviceIdentifier
               user.nickname = deviceIdentifier
               import md5
               user.password = md5.md5(deviceIdentifier).hexdigest()
               user.points = INITIAL_POINTS
               user.put()
               args[0].user = user
               get_new_questions(args[0].user)

            args[0].session['email'] = user.email

      if args[0].user:
         return fn(*args)
      else:
         args[0].error(403)
   return wrapper


def get_new_questions(user):
   query = Question.query(Question.moderated == 1)
   query = query.order(Question.queue).order(Question.numassigns).order(Question.askedon)
   new_questions = []
   for question in query.iter():
      found = False
      if user:
         if question.askedby == user.key:
            logging.info('{0} is own'.format(question.key.id()))
            continue
         elif Refused.query(Refused.refusedby == user.key, Refused.question == question.key).count() > 0:
            logging.info('{0} is refused'.format(question.key.id()))
            continue
         for q in user.assignedquestions:
            if q.question == question.key:
               logging.info('{0} already assigned'.format(question.key.id()))
               found = True
               break
      if not found:
         logging.info('assigning {0}'.format(question.key.id()))
         question.numassigns += 1
         question.put()
         new_questions += [AssignedQuestion(question=question.key, status='new')]
      if len(new_questions) >= QUESTIONS_NUMBER:
         break
   if len(new_questions) < QUESTIONS_NUMBER:
      logging.error('no more questions')
   if user:
      user.assignedquestions = new_questions
      user.assignedon = datetime.datetime.utcnow()
      user.put()
   else:
      return new_questions


def update_assigned_questions(user, batch_updates = False):
   num_unanswered = 0
   for aq in user.assignedquestions:
      if aq.status == 'new' or aq.status == 'in review':
         num_unanswered += 1
   if batch_updates:
      if num_unanswered == 0:
         user.assignedquestions = get_new_questions()
         user.assignedon = datetime.datetime.utcnow()
   else:
      if num_unanswered == 0:
         get_new_questions(user)
      else:
         user.put()

class BaseHandler(webapp2.RequestHandler):
   def dispatch(self):
      # Get a session store for this request.
      self.session_store = sessions.get_store(request=self.request)
      try:
        # Dispatch the request.
        webapp2.RequestHandler.dispatch(self)
      finally:
        # Save all sessions.
        self.session_store.save_sessions(self.response)

   @webapp2.cached_property
   def session(self):
      # Returns a session using the default cookie key.
      return self.session_store.get_session()

   def handle_exception(self, exception, debug):
      logging.info(exception)
      import sys, traceback, os
      trace = traceback.extract_tb(sys.exc_traceback)
      trace = trace[1:]
      trace = '\n'.join(os.path.basename(x[0])+':'+str(x[1]) for x in trace)
      logging.error(trace)
      self.error(str(exception))
      from google.appengine.api import mail
      mail.send_mail(sender='AskApp <askapp@banzaitokyo.com>',
                     to='toxa23@gmail.com',
                     subject='Error in the app',
                     body=str(exception) + '\n' + trace)

   def error(self, msg):
      if msg == 403:
         super(BaseHandler, self).error(403)
      else:
         self.output({'error': msg})

   def success(self, msg):
      self.output({'success': msg})

   def output(self, result):
      result = json.dumps(result)
      self.response.headers['Content-Type'] = 'application/json'
      self.response.write(result)
      #return result

   def extract_assigned_questions(self):
      questions = []
      for q in self.user.assignedquestions:
         questions += [q.question]
      questions = ndb.get_multi(questions)
      self.user._questions = []
      for q in questions:
         assignedquestion = None
         for aq in self.user.assignedquestions:
            if aq.question == q.key:
               assignedquestion = aq
         q = {'id': q.key.id(), 'question': q.question, 'status': assignedquestion.status}
         self.user._questions += [q]

   def refresh_questions(self):
      logging.info('Enter refresh')
      if datetime.datetime.utcnow() - self.user.assignedon > datetime.timedelta(hours=1):
         for aq in self.user.assignedquestions:
            old_question = aq.question.get()
            if old_question:
               old_question.numassigns -= 1
               old_question.put()
         get_new_questions(self.user)
      else:
         logging.info('Refresh: assigned on {0}, now {1}'.format(self.user.assignedon, datetime.datetime.utcnow()))

   def construct_user_profile(self):
      return {'email':self.user.key.id(), 'nickname': self.user.nickname, 'questions': self.user._questions,
              'assignedon': self.user.assignedon.strftime('%Y-%m-%d %H:%M:%S'),'points': self.user.points}

   def output_user_profile(self):
      self.extract_assigned_questions()
      self.output(self.construct_user_profile())


class Register(BaseHandler):
   def get(self):
      self.response.write('<h2>Register</h2><form method="post"><input type="text" name="form" value=\'{"email":"1@1.com", "password":"kostroma"}\' /><input type="submit" /></form>')

   def post(self):
      try:
         form = self.request.get('form')
         if not form:
            form = self.request.body
         form = json.loads(form)
      except:
         self.error('Wrong data')
         return
      email = form['email'].lower()
      password = form['password']
      if 'nickname' in form.keys():
         nickname = form['nickname']
      else:
         nickname = None
      if 'deviceIdentifier' in form.keys():
         deviceIdentifier = form['deviceIdentifier']
      else:
         deviceIdentifier = None
      if 'deviceToken' in form.keys():
         deviceToken = form['deviceToken']
      else:
         deviceToken = None
      from google.appengine.api import mail
      if not mail.is_email_valid(email):
         email = None
      if not email:
         self.error('Please provide valid email')
         return
      if len(password) < 3:
         self.error('Password too short')
         return

      user_key = ndb.Key(User, email)
      user = user_key.get()
      if user:
         self.error('This email is already registered')
         return

      self.session['email'] = email

      user = User()
      user.email = email
      import md5
      user.password = md5.md5(password).hexdigest()
      if nickname:
         user.nickname = nickname
      user.deviceidentifier = deviceIdentifier
      user.devicetoken = deviceToken
      user.points = INITIAL_POINTS
      self.user = user
      get_new_questions(self.user)

      self.output_user_profile()


class Login(BaseHandler):
   def get(self):
      self.response.write('<form method="POST"><input name="form" value="{\"email\": \"1@1.com\", \"password\": \"kostroma\", \"nickname\": \"1\"}" /><input type="submit" /></form>')
   def post(self):
      try:
         form = self.request.get('form')
         if not form:
            form = self.request.body
         form = json.loads(form)
      except:
         self.error('Wrong data')
         return
      email = form['email'].lower()
      password = form['password']
      user = User.query(User.email== email).fetch(1)
      if not len(user):
         self.error('Email is not registered')
         return
      else:
         user = user[0]
      import md5
      if user.password <> md5.md5(password).hexdigest():
         self.error('Wrong password')
         return
      modified = False
      if 'deviceIdentifier' in form.keys() and not user.deviceidentifier:
         user.deviceidentifier = form['deviceIdentifier']
         modified = True
      if 'deviceToken' in form.keys():
         user.devicetoken = form['deviceToken']
         modified = True
      if modified:
         user.put()
      self.session['email'] = user.key.id()
      self.user = user
      self.refresh_questions()
      self.output_user_profile()

   def get(self):
      self.response.write('<h2>Login</h2><form method="post"><input type="text" name="form" value=\'{"email":"1@1.com", "password":"kostroma"}\' /><input type="submit" /></form>')


class Logout(BaseHandler):
   def get(self):
      self.session['email'] = None
      self.success(True)


class RegisterDeviceToken(BaseHandler):
   def post(self):
      form = self.request.get('form')
      if not form:
         form = self.request.body
      form = json.loads(form)
      device_token = form['device_token']
      device_identifier = form['device_identifier']
      if 'moderator' in form.keys():
         appconfig = ApnConfig.get_or_insert("config")
         admin_devices = appconfig.admin_devices
         if not admin_devices:
            admin_devices = []
         else:
            admin_devices = json.loads(admin_devices)
         found = False
         for dev in admin_devices:
            if dev['device_identifier'] == device_identifier:
               dev['device_token'] = device_token
               found = True
         if not found:
            admin_devices += [{'device_identifier': device_identifier, 'device_token': device_token}]
         appconfig.admin_devices = json.dumps(admin_devices)
         appconfig.put()
      else:
         users = User.query(User.deviceidentifier == device_identifier).fetch(50)
         email = form['email'] if 'email' in form.keys() else None
         if (not users or len(users) == 0) and email:
            users = User.query(User.key == email).fetch(1)
         if not users or len(users) == 0:
            self.error('User not found')
            return
         for user in users:
            user.devicetoken = device_token
            user.put()
      self.success(True)


class Profile(BaseHandler):
   @authorized
   def get(self):
      self.refresh_questions()
      self.output_user_profile()

   @authorized
   def post(self):
      try:
         form = self.request.get('form')
         if not form:
            form = self.request.body
         form = json.loads(form)
      except:
         self.error('Wrong data')
         return
      if 'password' in form.keys():
         self.user.password = form['password']
      if 'nickname' in form.keys() and len(form['nickname']):
         self.user.nickname = form['nickname']
      else:
         self.user.nickname = None
      self.user.put()
      self.success(True)


class RefreshQuestions(BaseHandler):
   @authorized
   def get(self):
      self.refresh_questions()
      self.output_user_profile()


class Ask(BaseHandler):
   @authorized
   def post(self):
      if self.user.points < POINTS_TO_ASK:
         self.error('Not enough points')
         return

      try:
         form = self.request.body
         form = json.loads(form)
         qtext = form['question']
         if not qtext.endswith('?'):
            qtext = qtext + '?'
         #qtext = self.request.get('question')
      except:
         self.error('Wrong data')
         return
      question = Question()
      question.question = qtext
      question.askedby  = self.user.key
      question.put()
      self.user.points -= POINTS_TO_ASK
      self.user.put()
      self.success(True)

      #notify admin
      try:
         appconfig = ApnConfig.get_or_insert('config')
         admin_devices = appconfig.admin_devices
         if not admin_devices:
            return
         else:
            admin_devices = json.loads(admin_devices)
         tokens = []
         for dev in admin_devices:
            tokens += [dev['device_token']]
         from push import SendPushMessage
         sender = SendPushMessage()
         sender.post_for_admin(tokens, 'There is a new question')
      except Exception, e:
         logging.error('Push admin message failed {0}'.format(e))


class MakeAnswer(BaseHandler):
   @authorized
   def post(self):
      try:
         form = self.request.get('form')
         if not form:
            form = self.request.body
         form = json.loads(form)
         question = ndb.Key('Question', form['question'])
         answer_text = form['answer']
      except:
         self.error('Wrong data')
         return
      if not question:
         self.error('Question {0} not found'.format(form['question']))
         return
      assignedquestion = None
      for aq in self.user.assignedquestions:
         if aq.question == question:
            assignedquestion = aq
      if not assignedquestion:
         self.error('This question is no more assigned to you')
         return
      assignedquestion.status = 'in review'
      self.user.put()

      answer = Answer()
      answer.question = question
      answer.answer = answer_text
      answer.answeredby = self.user.key
      answer.answeredon = datetime.datetime.utcnow()
      answer.put()

      self.output_user_profile()

      #notify admin
      try:
         appconfig = ApnConfig.get_or_insert('config')
         admin_devices = appconfig.admin_devices
         if not admin_devices:
            return
         else:
            admin_devices = json.loads(admin_devices)
         tokens = []
         for dev in admin_devices:
            tokens += [dev['device_token']]
         from push import SendPushMessage
         sender = SendPushMessage()
         sender.post_for_admin(tokens, 'There is a new answer')
      except Exception, e:
         logging.error('Push admin message failed {0}'.format(e))


class RefuseQuestion(BaseHandler):
   @authorized
   def post(self):
      try:
         form = self.request.get('form')
         if not form:
            form = self.request.body
         form = json.loads(form)
         question = ndb.Key('Question', form['question'])
      except:
         self.error('Wrong data')
         return
      if not question:
         self.error('Question {0} not found'.format(form['question']))
         return

      assignedquestion = None
      for aq in self.user.assignedquestions:
         if aq.question == question:
            assignedquestion = aq
      if not assignedquestion:
         self.error('This question is no more assigned to you')
         return

      refused = Refused()
      refused.refusedby = self.user.key
      refused.question = question
      if 'reason' in form.keys():
         refused.reason = form['reason']
      refused.put()

      question = question.get()
      question.numassigns -= 1
      question.put()

      i = self.user.assignedquestions.index(assignedquestion)
      self.user.assignedquestions[i].status = 'refused'
      update_assigned_questions(self.user)

      self.output_user_profile()


class RateAnswer(BaseHandler):
   @authorized
   def post(self):
      try:
         form = self.request.get('form')
         if not form:
            form = self.request.body
         form = json.loads(form)
         answer = Answer.get_by_id(form['id'])
         helpful = form['helpful']
         detailed = form['detailed']
         funny = form['funny']
         getanotheranswer = 'getanotheranswer' in form
      except:
         self.error('Wrong data')
         return
      if not answer:
         self.error('Answer {0} not found'.format(form['id']))
         return
      answer.helpful = helpful
      answer.detailed = detailed
      answer.funny = funny
      answer.rated = 1
      answer.put()

      if getanotheranswer:
         if self.user.points < POINTS_TO_ASK:
            self.error('Not enough points')
            return
         question = answer.question.get()
         if not question:
            self.error('Question {0} not found'.format(answer.question.id()))
            return
         question.queue = 0
         question.put()
         self.user.points -= POINTS_TO_ASK
         self.user.put()
      self.success(True)


class MyQuestions(BaseHandler):
   @authorized
   def get(self):
      output = []
      questions = Question.query(Question.askedby == self.user.key).order(-Question.lastanswer).fetch(50)
      for question in questions:
         q = {'id': question.key.id(),
              'question': question.question,
              'askedon': question.askedon.strftime('%Y-%m-%d %H:%M:%S'),
              'numanswers': question.numanswers}
         output.append(q)

      self.output(output)


class Answers(BaseHandler):
   @authorized
   def get(self):
      try:
         question = self.request.get('question')
         question = ndb.Key(Question, int(question))
      except:
         self.error('Wrong data')
         return
      if not question:
         self.error('Question {0} not found'.format(self.request.get('question')))
         return
      answers = Answer.query(Answer.question == question, Answer.moderated == 1).order(-Answer.answeredon)
      output = []
      for answer in answers:
         q = {'id': answer.key.id(),
              'answer': answer.answer,
              'answeredon': answer.answeredon.strftime('%Y-%m-%d %H:%M:%S'),
              'helpful': answer.helpful,
              'detailed': answer.detailed,
              'funny': answer.funny,
              'rated': answer.rated}
         output.append(q)

      self.output(output)


class MyAnswers(BaseHandler):
   @authorized
   def get(self):
      answers = Answer.query(Answer.answeredby == self.user.key).order(-Answer.answeredon).fetch(50)
      output = []
      questions = []
      for answer in answers:
         questions += [answer.question]
      questions = ndb.get_multi(questions)
      for answer in answers:
         for q in questions:
            if q.key == answer.question:
               question = q
               break
         q = {'id': answer.key.id(),
              'question': question.question,
              'answer': answer.answer,
              'answeredon': answer.answeredon.strftime('%Y-%m-%d %H:%M:%S')}
         output.append(q)

      self.output(output)


class SingleAnswer(BaseHandler):
   def get(self):
      answer = self.request.get('id')
      answer = Answer.get_by_id(int(answer))
      if not answer:
         self.error('Answer {0} not found'.format(self.request.get('id')))
         return
      question = answer.question.get()
      if not question:
         self.error('Question {0} not found'.format(answer.question.id()))
         return
      self.user = question.askedby.get()
      if not self.session.get('email'):
         self.session['email'] = self.user.key.id()
      self.extract_assigned_questions()
      output = {
         'profile': self.construct_user_profile(),
         'question': {'id': question.key.id(),
                      'question': question.question,
                      'askedon': question.askedon.strftime('%Y-%m-%d %H:%M:%S'),
                     },
         'answer': {'id': answer.key.id(),
                    'questionText': question.question,
                    'answer': answer.answer,
                    'answeredon': answer.answeredon.strftime('%Y-%m-%d %H:%M:%S'),
                    'helpful': answer.helpful,
                    'detailed': answer.detailed,
                    'funny': answer.funny,
                    'rated': answer.rated
                   }
      }
      self.output(output)


class ModerateQuestions(BaseHandler):
   def get(self):
      if self.request.get('userid'):
         user = self.request.get('userid')
         if user.find('@') >= 0:
            user = User.get_by_id(user)
         else:
            user = User.get_by_id(int(user))
         if not user:
            self.error('User with id {0} not found'.format(self.request.get('userid')))
            return
         questions = Question.query(Question.askedby == user.key).fetch(100)
      else:
         questions = Question.query(Question.moderated == 0).fetch(100)
      result = []
      for q in questions:
         result = result + [{'id':q.key.id(), 'question': q.question, 'askedby': q.askedby.id(),
                             'askedon': q.askedon.strftime('%Y-%m-%d %H:%M:%S'), 'moderated': q.moderated}]
      self.output(result)

   def post(self):
      form = self.request.get('form')
      if not form:
         form = self.request.body
      form = json.loads(form)
      if 'ids' in form.keys():
         questions = form['ids']
      else:
         self.error('Wrong data')
         return
      if 'action' in form.keys():
         action = int(form['action']) # 1 to approve, -1 to reject
      else:
         self.error('Wrong data')
         return
      questions = questions.split(',')
      update_list = []
      for q in questions:
         question = Question.get_by_id(int(q))
         if question and question.moderated != action:
            question.moderated = action
            update_list += [question]
      if len(update_list):
         ndb.put_multi(update_list)

      self.success(True)


class ModerateAnswers(BaseHandler):
   def get(self):
      if self.request.get('userid'):
         user = self.request.get('userid')
         if user.find('@') >= 0:
            user = User.get_by_id(user)
         else:
            user = User.get_by_id(int(user))
         if not user:
            self.error('User with id {0} not found'.format(self.request.get('userid')))
            return
         answers = Answer.query(Answer.answeredby == user.key).fetch(100)
      else:
         answers = Answer.query(Answer.moderated == 0).fetch(100)
      result = []
      for a in answers:
         q = a.question.get()
         result += [{'id':a.key.id(), 'answer': a.answer, 'question':q.key.id(), 'questionText': q.question,
                    'answeredby': a.answeredby.id(), 'answeredon': a.answeredon.strftime('%Y-%m-%d %H:%M:%S'),
                    'moderated': a.moderated}]
      self.output(result)

   def post(self):
      form = self.request.get('form')
      if not form:
         form = self.request.body
      form = json.loads(form)
      if 'ids' in form.keys():
         answers = form['ids']
      else:
         self.error('Wrong data')
         return
      if 'action' in form.keys():
         action = int(form['action']) # 1 to approve, -1 to reject
      else:
         self.error('Wrong data')
         return

      silent = 'silent' in form.keys()
      answers = answers.split(',')
      update_answers = []
      update_questions = []
      update_users =[]
      for a in answers:
         answer = Answer.get_by_id(int(a))
         if not answer or answer.moderated == action:
            continue
         prev_moderated = answer.moderated
         answer.moderated = action
         update_answers += [answer]

         question = answer.question.get()
         if not question:
            if not silent:
               self.error('Question {0} not found'.format(answer.question.id()))
            continue
         if prev_moderated == 0:
            if action == 1:
               question.queue += 1 #move this question down in the questions stack
               question.numanswers += 1
               question.lastanswer = answer.answeredon
            question.numassigns -= 1
            update_questions += [question]
         elif prev_moderated == -1:
            question.numanswers += 1
            if question.lastanswer:
               question.lastanswer = max(answer.answeredon, question.lastanswer)
            else:
               question.lastanswer = answer.answeredon
            update_questions += [question]
         elif prev_moderated == 1 and action == -1:
            question.numanswers -= 1
            update_questions += [question]

         modified = False
         user = answer.answeredby.get()
         if prev_moderated == 0:
            user.points += POINTS_FOR_ANSWER*action
            modified = True

         for aq in user.assignedquestions:
            if aq.question == question.key:
               aq.status = 'answered' if action == 1 else 'banned'
               modified = True
         update_assigned_questions(user, True)
         if modified:
            update_users += [user]

         if question.askedby and action == 1:
            asker = question.askedby.get()
            if asker and asker.devicetoken:
               try:
                  from push import SendPushMessage
                  sender = SendPushMessage()
                  sender.post(asker.devicetoken, answer.key.id())
               except Exception, e:
                  receiver = asker.email if hasattr(asker, 'email') else question.askedby.id()
                  logging.error('Push message to {0} failed {1}'.format(receiver, e))

      if len(update_users):
         ndb.put_multi(update_users)
      if len(update_questions):
         ndb.put_multi(update_questions)
      if len(update_answers):
         ndb.put_multi(update_answers)

      if not silent:
         self.success(True)


class UserList(BaseHandler):
   def get(self):
      users = User.query().fetch(100)
      result = []
      for user in users:
         result += [{'id': user.key.id(), 'email': user.email, 'registeredon': user.registeredon.strftime('%Y-%m-%d %H:%M:%S')}]
      self.output(result)


class UserInfo(BaseHandler):
   def get(self):
      user = self.request.get('userid')
      if user.find('@') >= 0:
         user = User.get_by_id(user)
      else:
         user = int(user)
         user = User.get_by_id(user)
      if not user:
         self.error('User with id {0} not found'.format(self.request.get('userid')))
         return
      questions = Question.query(Question.askedby == user.key)
      num_questions = questions.count()
      num_approved_questions = questions.filter(Question.moderated == 1).count()
      num_rejected_questions = questions.filter(Question.moderated == -1).count()
      answers = Answer.query(Answer.answeredby== user.key)
      num_answers = answers.count()
      num_approved_answers = answers.filter(Answer.moderated == 1).count()
      num_rejected_answers = answers.filter(Answer.moderated == -1).count()
      self.output({'userid': user.key.id(), 'email':user.email, 'nickname': user.nickname,
              'registeredon': user.registeredon.strftime('%Y-%m-%d %H:%M:%S'), 'points': user.points,
              'questions': {'total': num_questions, 'approved': num_approved_questions, 'rejected': num_rejected_questions},
              'answers': {'total': num_answers, 'approved': num_approved_answers, 'rejected': num_rejected_answers}})


class MainPage(BaseHandler):
   def get(self):
      email = self.session.get('email')
      self.user = None
      if email:
         user_key = ndb.Key(User, email)
         self.user = user_key.get()
      self.response.write("<h1>aaask-application</h1>")
      if not self.user:
         self.response.write('<a href="/login">Login</a>')
         return
      hello = self.user.nickname
      if not hello:
         hello = self.user.key.id()
      self.response.write('Hello, ' + hello)
      self.response.write(' <a href="/logout">Logout</a>')
      self.response.write('<br />')
      """q1 = QuestionsToMe()
      q1 = q1.get()
      self.response.write(q1)
      q1 = MyQuestions()
      q1 = q1.get()
      self.response.write(q1)"""


class SystemQuestion(BaseHandler):
   def get(self):
      self.response.write('Create system questions')
      self.response.write('<form method="POST"><input type="text" name="question" value="System question" /><input type="submit" /></form>')

   def post(self):
      qt = self.request.get('question')
      if not qt: return
      q = Question()
      q.question = qt
      q.queue = 999
      q.moderated = 1
      q.put()
      self.response.write('Question created <a href="/populatequestions">Ask another</a>')


class ConfigureApp(webapp2.RequestHandler):
    def get(self):
        if self.request.get('password') != 'kostroma':
           self.response.write('You forgot to specify the password')
           return

        appconfig = ApnConfig.get_or_insert("config")

        if not appconfig.gcm_api_key:
            appconfig.gcm_api_key = "<gcm key here>"
        if not appconfig.gcm_multicast_limit:
            appconfig.gcm_multicast_limit = 1000
        if not appconfig.apns_multicast_limit:
            appconfig.apns_multicast_limit = 1000
        if appconfig.apns_test_mode == None:
            appconfig.apns_test_mode = True
        if not appconfig.apns_sandbox_cert:
            appconfig.apns_sandbox_cert = "<sandbox pem certificate string>"
        if not appconfig.apns_sandbox_key:
            appconfig.apns_sandbox_key = "<sandbox pem private key string>"
        if not appconfig.apns_cert:
            appconfig.apns_cert = "<pem certificate string>"
        if not appconfig.apns_key:
            appconfig.apns_key = "<pem private key string>"
        if not appconfig.apns_admin_cert:
            appconfig.apns_admin_cert = "<pem certificate string>"
        if not appconfig.apns_admin_key:
            appconfig.apns_admin_key = "<pem private key string>"

        appconfig.put()

        template_values = {
            'appconfig': appconfig,
        }
        from google.appengine.ext.webapp import template
        import os
        path = os.path.join(os.path.dirname(__file__), 'apnconfig.html')
        self.response.out.write(template.render(path, template_values))

    def post(self):
        if self.request.get('password') != 'kostroma':
           self.response.write('You forgot to specify the password')
           return

        appconfig = ApnConfig.get_or_insert("config")
        appconfig.gcm_api_key = self.request.get("gcm_api_key")
        appconfig.gcm_multicast_limit = int(self.request.get("gcm_multicast_limit"))
        appconfig.apns_multicast_limit = int(self.request.get("apns_multicast_limit"))
        appconfig.apns_sandbox_cert = self.request.get("apns_sandbox_cert")
        appconfig.apns_sandbox_key = self.request.get("apns_sandbox_key")
        appconfig.apns_cert = self.request.get("apns_cert")
        appconfig.apns_key = self.request.get("apns_key")
        appconfig.apns_admin_cert = self.request.get("apns_admin_cert")
        appconfig.apns_admin_key = self.request.get("apns_admin_key")

        if self.request.get("apns_test_mode") == 'True':
            appconfig.apns_test_mode = True
        else:
            appconfig.apns_test_mode = False

        appconfig.put()
        self.get()


class TestPush(webapp2.RequestHandler):
   def get(self):
      from push import SendPushMessage
      sender = SendPushMessage()
      """answers = Answer.query().order(-Answer.question).fetch(10)
      for answer in answers:
         question = answer.question.get()
         if question.askedby:
            self.response.write('A: {0}, Q: {1}'.format(answer.key.id(), question.key.id()))
            sender.post('bc49fd3d483e8975933828872aabd848941d4cdc6835550c5cd6cb162c239494', answer.key.id())
            break"""
      sender.post_for_admin(['2330ed34f16c583c443c2e41484b09c6b46de04781ea6c460a9ab488533c15d2'], 'test admin')
      self.response.write('OK')

class UpdateAssigned(webapp2.RequestHandler):
   def get(self):
      u = User.get_by_id(6333186975989760)
      u.assignedon = datetime.datetime.utcnow() - datetime.timedelta(hours=2)
      u.put()
      return
      users = Question.query().fetch()
      for u in users:
         if u.askedby:
            u.moderated = 0
            u.put()
      self.response.write('OK')

config = {}
config['webapp2_extras.sessions'] = {
    'secret_key': 'aaask',
    'apns_test_mode': True
}
application = webapp2.WSGIApplication([
   ('/', MainPage),
   ('/register', Register),
   ('/login', Login),
   ('/logout', Logout),
   ('/registerdevice', RegisterDeviceToken),
   ('/profile', Profile),
   ('/refreshq', RefreshQuestions),
   ('/ask', Ask),
   ('/answer', MakeAnswer), # not "Answer" because it is already exists in dataclasses.py
   ('/refuse', RefuseQuestion),
   ('/rateanswer', RateAnswer),
   ('/myquestions', MyQuestions),
   ('/answers', Answers),
   ('/myanswers', MyAnswers),
   ('/singleanswer', SingleAnswer),

   ('/moderateq', ModerateQuestions),
   ('/moderatea', ModerateAnswers),
   ('/userlist', UserList),
   ('/userinfo', UserInfo),

   ('/populatequestions', SystemQuestion),
   ('/configapn', ConfigureApp)
   ,('/testpush', TestPush)
   ,('/updateassigned', UpdateAssigned)
], config=config, debug=True)