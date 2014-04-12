World Domination Summit
=======================

Welcome to documentation for the WDS Site!

Details about editing content for the page are directly below. Developer documentation 
can be found [here](https://github.com/nickyhajal/world-domination-summit/wiki)

## Table of Contents

### Overview

* [How Content is Created and Edited for WDS](#overview)

### Managing Content

* [Creating a Page](#creating-a-page)
* [Editing a Page](#editing-a-page)
* [Formatting Content](#formatting-content)
* [Page Settings](#page-settings)
* [Setting a Sidebar](#setting-a-sidebar)
* [Adding Decoration](#adding-decoration)

### Content Assets

* [Using Wufoo for Forms](#using-wufoo)
* [How to Upload Images](#uploading-images)

### Advanced

* [Custom CSS](#custom-css)
* [Private editing](#private-editing)

---------------------------------------

## Overview

As of WDS 2014, all content on the WDS site is managed right here from GitHub. 

You can easily create and edit pages from GitHub's interface, hit save and your changes are instantly sent to the WDS server and made live.

A page is created just by typing normally - text can be styled with either Markdown (super-easy and explained more below) or normal HTML.

Every change you make is tracked so if any problems occur, you can always roll back.

The guide below explains all the details of how this system works.

## Managing Content

### Creating a File

Let's get started!

To create a file you'll first want to click into the `_content` folder. This is the folder where *all* content pages should be. The only other folder you may need is `_sidebars` - you can ignore all others listed.


![The _content folder is important](https://www.evernote.com/shard/s10/sh/571149cc-b6e5-4b8e-8c13-f2e1208558b0/abfdb283c302da807a238ff8c5d2d37c/res/10aeff6c-b68e-4aae-b096-3f668826ff80/skitch.png?resizeSmall&width=832)


Once in the `_content` directory, click the small page-with-a-plus icon to create a new file there.

![Click the page-with-a-plus icon to create a file](https://www.evernote.com/shard/s10/sh/60d85ad9-82fb-4673-ada9-47c042fa6b0b/a556167fb0fd3d5b98600a89fee5f33b/res/364586cc-612d-45c3-8a03-bdaa0b10ef28/skitch.png?resizeSmall&width=832)


#### Welcome to the Text Editor

Now you're in the GitHub text editor, nice work so far!

The first task is to name your file in the textbox that says "Name your file..."

![Name your file here](https://www.evernote.com/shard/s10/sh/790ef366-36f4-481a-9f8a-05d218727d0a/b6a24e6f91ee898163b9492b8d6c5685/res/e0f35281-1221-4bd6-b240-2cf605989f63/skitch.png?resizeSmall&width=832)

**Important**: The name of your file should always end in `.md` (as in: MarkDown)

**Also Important**: The name you give your file is what the path will ultimately be. It should be all lowercase and use plain dashes instead of spaces.

So, if you create a file called: dont-stop-believin.md, that will create a page at http://worlddominationsummit.com/dont-stop-believin

#### Adding Content and Saving Your Page

Now, all you need to do is add some content into the big text area (more details on formatting that content below) and click the `Commit Changes` button - think of that as a "Save & Publish" button.

![Commit Changes Button Saves and Publishes Your Page](https://www.evernote.com/shard/s10/sh/e05ddfec-ad7c-4ca2-9685-04d8545abd7e/a00a8ee7323e2b8b9c8a725b58ce80c4/res/cca7e3d6-8fd5-40df-8858-8217bc2551b7/skitch.png?resizeSmall&width=832)

Boom! You just created a page!

### Editing an Existing Page

To edit an existing page, click on the filename in the `_content` folder and then click the `Edit` button.

![Click the edit button to edit an existing page](https://www.evernote.com/shard/s10/sh/845ec671-6e68-4b23-82b7-1580c9731de6/70dd563b4e25f1bab573c6ef3e8ecd90/res/fbc8e231-034f-4cb9-9c6d-835e149a9d7b/skitch.png?resizeSmall&width=832)


### Formatting Content



