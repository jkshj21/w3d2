DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL

);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  reply_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
  FOREIGN KEY (reply_id) REFERENCES replies(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);




INSERT INTO
  users (fname, lname)
VALUES
  ('John', 'Doe'),
  ('Jane', 'Doe'),
  ('new', 'user');


INSERT INTO
  questions (title, body, user_id)
VALUES
  ('Question One:', "This is the first question?", 1),
  ('Question Two:', "This is the second question?", 2),
  ('Question Three:', "This is the third question?", 3);


INSERT INTO
  replies (reply_id, question_id, user_id, body)
VALUES
  (NULL, 1, 1, 'first question, response 1'),
  (1, 1, 2, 'first question, response 2'),
  (2, 1, 2, 'first question, response 3'),
  (NULL, 2, 2, 'second question, response 1'),
  (4, 2, 2, 'second question, response 2'),
  (3, 1, 2, 'first question, response 4'),
  (5, 2, 2, 'second question, response 3');
INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (1, 1),
  (2, 1),
  (3, 1),
  (1, 2),
  (2, 2);

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (1, 1),
  (2, 1),
  (3, 1),
  (1, 2),
  (2, 2),
  (3, 1);
