#|
 This file is a part of lichat
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:cl-user)
(defpackage #:lionchat
  (:nicknames #:org.shirakumo.lichat.lionchat)
  (:use #:cl+qt #:lichat-tcp-client)
  (:shadow #:client)
  (:export
   #:start))
