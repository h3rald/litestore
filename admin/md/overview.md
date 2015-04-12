## Overview

LiteStore is a lightweight, self-contained, RESTful, multi-format document store server written in [Nim](http://www.nim-lang.org). It aims to be a very simple and lightweight backend ideal for prototyping and testing REST APIs and single-page applications.

### Rationale 

If you ever wanted to build a simple single-page application in your favorite framework, just to try something out or as a prototype, you inevitably had to answer the question _"What backend should I use?"_

Sure, setting up a simple REST service using [Sinatra](http://www.sinatrarb.com) or [Express.js](http://expressjs.com) is not very hard, but if you want to distribute it, that backend will become a prerequisite for your app: you'll either distribute it with it, or install it beforehand on any machine you want to try your app on. Which is a shame, really, because single-page-applications are meant to be running anywhere _provided that they can access their backend_.

LiteStore aims to solve this problem. When you use LiteStore as the backend for your app, you only need to take _two files_ with you, at all times:

* The [litestore](class:cmd) executable file for your platform of choice (that's about 2MB in size)
* A datastore file

And yes, you can even store the code of your client-side application inside the datastore itself, along with your application data.

### Key Features

Despite being fairly small and self-contained, LiteStore comes with many useful features that are essential for many [use cases](#Use.Cases).

#### Multiformat documents

LiteStore can be used to store documents in virtually any format 

#### Document Tagging

#### Full-text Search

#### RESTful HTTP API

#### Directory Bulk Import/Export

#### Directory Mounting and Mirroring

### Use Cases

#### SPA prototyping backend

#### Personal Wiki/CMS backend

#### Static site backend

#### Lightweight file server

### Architecture

![LiteStore Architecture](images/litestore_arch.png)