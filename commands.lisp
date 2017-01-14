#|
 This file is a part of lichat
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.lichat.lionchat)
(in-readtable :qtools)

(defvar *commands* (make-hash-table :test 'equal))

(defun command (name)
  (gethash (string-downcase name) *commands*))

(defun (setf command) (function name)
  (setf (gethash (string-downcase name) *commands*) function))

(defun remove-command (name)
  (remhash (string-downcase name) *commands*))

(defun list-commands ()
  (loop for k being the hash-keys of *commands*
        collect k))

(defun split-command-string (string)
  (let ((args))
    (with-input-from-string (input string)
      (loop with buffer = (make-string-output-stream)
            for char = (read-char input NIL)
            while char
            do (case char
                 (#\\ (write-char (read-char input) buffer))
                 (#\  (push (get-output-stream-string buffer) args))
                 (T (write-char char buffer)))
            finally (push (get-output-stream-string buffer) args))
      (nreverse args))))

(defmethod show-update-text (channel type text)
  (let ((update (make-instance type
                               :from "Lionchat"
                               :text text)))
    (setf (client update) (client channel))
    (update (main (client channel)) update)))

(defun run-command (channel string)
  (let* ((args (split-command-string string))
         (command (command (first args))))
    (handler-case
        (if command
            (handler-case (apply command channel (rest args))
              (error (err)
                (declare (ignore err))
                (error "Invalid syntax. Expected: /~a~{ ~a~}"
                       (first args)
                       (rest (trivial-arguments:arglist command)))))
            (error "Unknown command ~a" (first args)))
      (error (err)
        (show-update-text channel 'lichat-protocol:failure (princ-to-string err))))))

(defmacro define-command (prefix (channel &rest args) &body body)
  `(setf (command ,(string prefix))
         (lambda (,channel ,@args)
           ,@body)))

(define-command help (channel)
  (show-update-text channel 'lichat-protocol:text-update
                    (format NIL "The following commands are available: ~{~a~^, ~}"
                            (list-commands))))

(define-command create (channel &optional name)
  (qsend channel 'lichat-protocol:create :channel name))

(define-command join (channel name)
  (qsend channel 'lichat-protocol:join :channel name))

(define-command leave (channel &optional (name (name channel)))
  (qsend channel 'lichat-protocol:leave :channel name))

(define-command pull (channel user &optional (name (name channel)))
  (qsend channel 'lichat-protocol:pull :channel name :target user))

(define-command kick (channel user &optional (name (name channel)))
  (qsend channel 'lichat-protocol:kick :channel name :target user))

(define-command users (channel &optional (name (name channel)))
  (qsend channel 'lichat-protocol:users :channel name))

(define-command channels (channel)
  (qsend channel 'lichat-protocol:channels))

(define-command info (channel user)
  (qsend channel 'lichat-protocol:user-info :target user))

(define-command message (channel name &rest text)
  (qsend channel 'lichat-protocol:message :channel name :text (format NIL "~{~a~^ ~}" text)))

(define-command contact (channel &rest users)
  (unless users
    (error "I'll need at least one user to contact."))
  (let ((id (lichat-protocol:id (qsend channel 'lichat-protocol:create))))
    (with-awaiting (update id (main (client channel)))
      (typecase update
        (lichat-protocol:join
         (dolist (user users)
           (qsend channel 'lichat-protocol:pull
                  :channel (lichat-protocol:channel update) :target user)))
        (lichat-protocol:update-failure
         (error "Failed to create contact channel: ~a"
                (lichat-protocol:text update)))))))

(define-command p (channel)
  (prev-channel (main (client channel))))

(define-command n (channel)
  (next-channel (main (client channel))))

(define-command c (channel name/index)
  (setf (channel (main (client channel)))
        (or (ignore-errors (parse-integer name/index))
            name/index)))
