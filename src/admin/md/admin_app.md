## Administration App

A simple, *slightly* dated, but fully-functional administration app can be used to manage LiteStore data stores. This app can simply be imported into a data store file and then run via LiteStore.

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

When first loaded, the app loads the _Info_ page by default. This pages contains useful information on the currently-loaded LiteStore data store, some stats on documents and tags, and links to access documents by tag.

![Info Page](images/app_info.png)

#### Read LiteStore Documentation

The **Guide** section of the Administration App contains the official LiteStore User Guide, conveniently split into separate pages by section. 

> %note%
> Note
>
> If the data store is loaded in read/write mode (default), you'll see some **Edit** buttons on the Guide pages. Clicking them will open the corresponding Markdown source document for editing -- Such links have been very useful to update the docs in-place!

![Guide](images/app_guide.png)

#### Display Documents by Tag

By clicking any of the tag links on the _Info_ page or by accessing the **Tags** menu in the navigation bar you can browse all documents tagged with a specific tag. Currently, it is only possible to specify only one single tag at a time although the API allows several tags to be specified at once. 

![Display documents by tag](images/app_tags.png)

#### Search Documents

You can search for documents using the search box in the navigation bar. The Administration App lets you search through all the textual/searchable documents loaded in the currently open data store.

![Search](images/app_search.png)

#### View, Preview, Delete, Create and Edit Documents

You can view, edit and delete any document loaded in the data store using the bundled [ACE Editor](http://ace.c9.io/) component. Additionally:

* It is possible to upload local files instead of creating them by hand.
* Preview is available for images and HTML documents
* Source code highlighting is available for Javascript, CSS, HTML, JSON and Markdown files.

![Document](images/app_document.png)