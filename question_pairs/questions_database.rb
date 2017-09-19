require 'sqlite3'
require 'singleton'


class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end




# class Superclass
#
#
#   def self.find_by_id(id)
#     instance_table = QuestionsDatabase.instance.execute(<<-SQL, @@table, id)
#     SELECT
#       *
#     FROM
#       ?
#     WHERE
#       id = ?
#     SQL
#
#     instance_table.first
#   end
#
# end



class User
  attr_accessor :fname, :lname
  attr_reader :id

  @@table = 'users'

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end
  #
  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    return nil unless user.length > 0
    User.new(user.first)
  end
  def self.initialize
    super
    @table = 'users'
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL
    return nil unless user.length > 0
    User.new(user.first)
  end

  def initialize(options = {})

    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']

  end

  def save
    if @id
      self.update
    else
      QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, fname, lname, id)
    UPDATE
      users (fname, lname)
    SET
      fname = ?, lname = ?
    WHERE
      id = ?
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(self.id)
  end

  def average_karma
    user = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT
      CAST(COUNT(DISTINCT question_likes.question_id) AS FLOAT) / (COUNT(DISTINCT questions.id)) AS avg_karma
      -- / CAST(COUNT(COALESCE(DISTINCT question_likes.question_id, 0)) AS FLOAT)) AS avg_karma
      -- COUNT(COALESCE(question_likes.question_id, 0))
    FROM
      questions
    LEFT OUTER JOIN
      question_likes ON questions.id = question_likes.question_id
    GROUP BY
      question_likes.question_id
    HAVING
      questions.user_id = ?
    SQL
    user
  end
end




class Question
  attr_accessor :title, :body
  attr_reader :id, :user_id

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*, COUNT(question_follows.id) AS num_followers
    FROM
      questions
    JOIN
      question_follows ON questions.id = question_follows.question_id
    GROUP BY
      question_follows.question_id
    ORDER BY
      COUNT(question_follows.id) DESC
    LIMIT
      ?
    SQL
    questions
  end

  def self.most_liked(n)
    QuestionLikes.most_liked_questions(n)
  end

  def self.most_followed
    Question.most_followed_questions(1)
  end

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    return nil unless question.length > 0
    Question.new(question.first)
  end

  def self.find_by_author_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      questions
    WHERE
      user_id = ?
    SQL
    return nil unless questions.length > 0
    arr_questions = []
    questions.each do |question|
      arr_questions << Question.new(question)
    end
    arr_questions
  end

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def save
    if @id
      self.update
    else
      QuestionsDatabase.instance.execute(<<-SQL, title, body, user_id)
      INSERT INTO
        users (title, body, user_id)
      VALUES
        (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, title, body, user_id, id)
    UPDATE
      users (title, body, user_id)
    SET
      title = ?, body = ?, user_id = ?
    WHERE
      id = ?
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    author = User.find_by_id(self.user_id)
    puts "Author: #{author.fname} #{author.lname}"
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    QuestionFollows.followers_for_question_id(self.id)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end
end




class QuestionFollows
  attr_reader :id, :user_id, :question_id

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      users
    JOIN
      question_follows ON users.id = question_follows.user_id
    WHERE
      question_follows.question_id = ?
    SQL
    users
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_follows ON questions.id = question_follows.question_id
    WHERE
      question_follows.user_id = ?
    SQL
    questions
  end
end




class Reply
  attr_accessor :body
  attr_reader :id, :user_id, :reply_id, :question_id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    return nil unless reply.length > 0
    Reply.new(reply.first)
  end

  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
    SQL
    return nil unless reply.length > 0
    arr_replies = []
    replies.each do |reply|
      arr_replies << Reply.new(reply)
    end
    arr_replies
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ?
    SQL
    return nil unless reply.length > 0
    arr_replies = []
    replies.each do |reply|
      arr_replies << Reply.new(reply)
    end
    arr_replies
  end

  def initialize(options = {})
    @id = options['id']
    @reply_id = options['reply_id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @body = options['body']
  end

  def save
    if @id
      self.update
    else
      QuestionsDatabase.instance.execute(<<-SQL, reply_id, question_id, user_id, body)
      INSERT INTO
        users (reply_id, question_id, user_id, body)
      VALUES
        (?, ?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, reply_id, question_id, user_id, body, id)
    UPDATE
      users (reply_id, question_id, user_id, body)
    SET
      reply_id = ?, question_id = ?, user_id = ?, body = ?
    WHERE
      id = ?
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    author = User.find_by_id(self.user_id)
    puts "Author: #{author.fname} #{author.lname}"
  end

  def question
    Question.find_by_id(self.question_id)
  end

  def parent_reply
    raise "No id" if self.reply_id.nil?
    Reply.find_by_id(self.reply_id)
  end

  def child_replies
    self.reply_id ||= 0
    # reply_id += 1
    reply = QuestionsDatabase.instance.execute(<<-SQL, question_id, self.reply_id+1)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ? AND reply_id = ?
    SQL
    return nil unless reply.length > 0
    reply.first
  end
end




class QuestionLikes
  attr_reader :id, :user_id, :question_id

  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      users
    JOIN
      question_likes ON users.id = question_likes.user_id
    WHERE
      question_likes.question_id = ?
    SQL
    users
  end

  def self.num_likes_for_question_id(question_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(question_likes.id) AS num_likes
    FROM
      questions
    JOIN
      question_likes ON questions.id = question_likes.question_id
    GROUP BY
      question_likes.question_id
    HAVING
      question_id = ?
    SQL
    questions
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      COUNT(question_likes.id) AS num_liked_questions
    FROM
      users
    JOIN
      question_likes ON users.id = question_likes.user_id
    GROUP BY
      question_likes.user_id
    HAVING
      user_id = ?
    SQL
    questions
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      questions.*, COUNT(question_likes.id) AS most_liked_question
    FROM
      questions
    JOIN
      question_likes ON questions.id = question_likes.question_id
    GROUP BY
      question_likes.question_id
    ORDER BY
      COUNT(question_likes.id) DESC
    LIMIT
      ?
    SQL
    questions
  end


  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

end

# QuestionsDatabase.instance
# p User.find_by_id(1)
