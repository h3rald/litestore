## Overview

LiteStore is a lightweight, self-contained, RESTful, multi-format NoSQL document store server written in [Nim](http://www.nim-lang.org) and powered by a [SQLite](http://www.sqlite.org) backend for storage. It aims to be a very simple and lightweight backend ideal for prototyping and testing REST APIs and single-page applications.

### Rationale

If you ever wanted to build a simple single-page application in your favorite framework, just to try something out or as a prototype, you inevitably had to answer the question _"What backend should I use?"_

Sure, setting up a simple REST service using [Sinatra](http://www.sinatrarb.com) or [Express.js](http://expressjs.com) is not very hard, but if you want to distribute it, that backend will become a prerequisite for your app: you'll either distribute it with it, or install it beforehand on any machine you want to try your app on. Which is a shame, really, because single-page-applications are meant to be running anywhere _provided that they can access their backend_.

LiteStore aims to solve this problem. When you use LiteStore as the backend for your app, you only need to take _two files_ with you, at all times:

* The [litestore](class:cmd) executable file for your platform of choice (just a few MBs in size)
* A data store file

And yes, you can even store the code of your client-side application inside the datastore itself, along with your application data.

### Key Features

Despite being fairly small and self-contained, LiteStore comes with many useful features that are essential for many use cases.

#### Multi-format Documents

LiteStore can be used to store documents in virtually any format, as long as you specify an appropriate content type for them. Textual documents are stored as-is, while binary documents are base64-encoded (not the best thing in the world, but definitely the easiest and most portal option).

#### Document Tagging

You can add custom tags to documents to easily categorize them and retrieve them. Some system tags are also added automatically to identify the document content type, format and collection.

#### Enhanced Querying of JSON documents

By leveraging the [SQLite JSON1 extension](https://www.sqlite.org/json1.html) and implementing custom query string parsing, LiteStore provides enhanced filtering, ordering, and custom field selection of JSON documents. Additionally, you can also configure custom indexes specifying JSON fields for extra speed!

#### Full-text Search

By leveraging [SQLite FTS4 extension](http://www.sqlite.org/fts3.html) and implementing an enhanced algorithm for result rankings, LiteStore provides full-text search for all textual documents out-of-the-box.

#### RESTful HTTP API

Every operation can be performed on the data store using a simple but powerful RESTful HTTP API, perfect for client-side, single-page applications.

#### JWT-based Authorization

LiteStore can be configured to validate [JWT](https://jwt.io/) tokens and configure access to specific resources based on specific [OAuth2 scopes](https://oauth.net/2/scope/).

#### Middleware

By leveraging the [duktape](https://duktape.org/) library, you can create your own middleware functions in JavaScript to perform additional tasks (validation, logging, data aggregation...) before accessing data.

#### Nim API

If you want, you can use LiteStore as a [Nim](https://nim-lang.org) library and perform data store operations from your own Nim program.

#### Command-line API

Every operation can also be performed from command line, using the [litestore execute](class:cmd) command.

#### Directory Bulk Import/Export

To make serving a single-page application _from LiteStore_ even easier and faster, you can automatically import (and export) the contents of a directory recursively.

#### Directory Mounting and Mirroring

After importing the contents of a directory into a LiteStore data store, you can _mount it_ on LiteStore and mirror all data store changes to the filesystem. Incidentally, that's how most of the LiteStore Admin test app was built [](class:fa-smile-o).