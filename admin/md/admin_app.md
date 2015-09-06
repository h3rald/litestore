## Administration App

A simple but fully-functional administration app can be used to manage LiteStore data stores. This app can simply be imported into a data store file and then run via LiteStore.

### Obtaining and Running the Administration App

There are two ways to get the Administration App:

* Using a pre-populated data store file
* Manually importing the [admin](class:dir) directory into any data store file

#### Using a Pre-populated Data Store File

If you are using the [data.db](class:file) data store file distributed with the pre-built LiteStore binaries, you don't have to do anything: the Administration App is already bundled in the datastore file. You simply have to run LiteStore and access the app at the following address: <http://localhost:9500/docs/admin/index.html>.

#### Importing the admin directory

If you are using your own data store file, you can still import the Administration App in it by downloading the LiteStore source files or cloning the LiteStore repository from [Github](https://github.com/h3rald/litestore) and running LiteStore with the following arguments and options from the top-level directory of the LiteStore repository:

[litestore -d:admin import](class:cmd)

Once the import is completed, you can run litestore and access the app at the following address: <http://localhost:9500/docs/admin/index.html>.

### Main Functionalities

The LiteStore Administration App is a single-page application built using the [Mithril](https://lhorie.github.io/mithril/) Javascript framework and other open source software like [Bootstrap](http://getbootstrap.com/) and the [ACE Editor](http://ace.c9.io/).

It can be used to easily access and explore any LiteStore data store (provided that it has been loaded in it) and access most of LiteStore functionalities via its HTTP API.

#### View Data Store Information

When first loaded, the app loads the _Info_ page by default.

#### Read LiteStore Documentation

#### Display Documents by Tag

#### Search Documents

#### View, Preview, Create and Edit Documents