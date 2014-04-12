World Domination Summit
=======================

Welcome to documentation for the WDS Site!

Details about editing content for the page are directly below. Developer documentation 
can be found [here](https://github.com/nickyhajal/world-domination-summit/wiki)

## Table of Contents

### Overview

* [How Content is Created and Edited for WDS](#overview)

### Managing Content (Start Here)

* [Creating a Page](#creating-a-page)
* [Editing a Page](#editing-a-page)
* [Formatting Content](#formatting-content)
* [Page Settings](#page-settings)
* [Setting a Sidebar](#setting-a-sidebar)


### Content Assets

* [Adding Decoration](#adding-decoration)
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

---

Once in the `_content` directory, click the small page-with-a-plus icon to create a new file there.

![Click the page-with-a-plus icon to create a file](https://www.evernote.com/shard/s10/sh/60d85ad9-82fb-4673-ada9-47c042fa6b0b/a556167fb0fd3d5b98600a89fee5f33b/res/364586cc-612d-45c3-8a03-bdaa0b10ef28/skitch.png?resizeSmall&width=832)

---


#### Welcome to the Text Editor

Now you're in the GitHub text editor, nice work so far!

The first task is to name your file in the textbox that says "Name your file..."

![Name your file here](https://www.evernote.com/shard/s10/sh/790ef366-36f4-481a-9f8a-05d218727d0a/b6a24e6f91ee898163b9492b8d6c5685/res/e0f35281-1221-4bd6-b240-2cf605989f63/skitch.png?resizeSmall&width=832)

---

**Important**: The name of your file should always end in `.md` (as in: MarkDown)

**Also Important**: The name you give your file is what the path will ultimately be. It should be all lowercase and use plain dashes instead of spaces.

So, if you create a file called: dont-stop-believin.md, that will create a page at http://worlddominationsummit.com/dont-stop-believin

#### Adding Content and Saving Your Page

Now, all you need to do is add some content into the big text area (more details on formatting that content below) and click the `Commit Changes` button - think of that as a "Save & Publish" button.

![Commit Changes Button Saves and Publishes Your Page](https://www.evernote.com/shard/s10/sh/e05ddfec-ad7c-4ca2-9685-04d8545abd7e/a00a8ee7323e2b8b9c8a725b58ce80c4/res/cca7e3d6-8fd5-40df-8858-8217bc2551b7/skitch.png?resizeSmall&width=832)
---

Boom! You just created a page!

### Editing an Existing Page

To edit an existing page, click on the filename in the `_content` folder and then click the `Edit` button.

![Click the edit button to edit an existing page](https://www.evernote.com/shard/s10/sh/845ec671-6e68-4b23-82b7-1580c9731de6/70dd563b4e25f1bab573c6ef3e8ecd90/res/fbc8e231-034f-4cb9-9c6d-835e149a9d7b/skitch.png?resizeSmall&width=832)


### Formatting Content

For the most part, you can just type and all your content will be properly formatted to fit the style of the WDS site but there are a few details to note.

#### Markdown

Markdown is an easy way to format text used all over the web - you may be using it without even realizing.

If you've ever used `*asterisks*` to italicize something - that's Markdown!

With Markdown you can also 

Create links: `[Link Text](http://link-to-this-site.com)`

Add images: `![Image title](http://link-to-image.com/the-image.png)`

#### Headings in Markdown

Every single page should have a main heading and sub-headings are an important part of creating readable pages - so let's take a second to talk about them.

---

In Markdown, any line starting with a pound sign (#) becomes a heading. A top level heading has just one pound sign and adding additional pound signs decreases the importance.

`# This is a top-level heading in Markdown`

`## This is a second-level heading`

`### This is a third-level heading`

**Important**: Every single page you create should either start with a first-level or second-level heading. 

If you start with a first-level heading, the heading will look like this: 

![Pages created with a first-level heading](https://www.evernote.com/shard/s10/sh/1995adf6-7c07-46b2-9589-2a9bd59ef7fd/d857298086fa5928f1a92401810db5e7/res/deed3354-375f-4315-b5f9-dbebe613925c/skitch.png?resizeSmall&width=832)

---

If you start with a second-level heading (Two pound signs), the heading will look like this: 

![Pages created with a second-level heading](https://www.evernote.com/shard/s10/sh/f3f66ea6-c5fb-4e94-8db8-f3e33e7e1c0e/67c7b369f2c4a86b2018249f553b9a3d/res/5ee5559d-605b-496d-b92e-d9c69be71662/skitch.png?resizeSmall&width=832)

---

Notice above that once we're in the main body content, we use third-level and below headings (three pound signs!).

#### Here's what's cool + learn more

Here's what's awesome about this: you don't really have to worry about page styling at all. 

Just write normal text with these few simple rules and then the site will automatically turn that into a beautiful page for you.

**Want to learn more Markdown to spruce up your pages?** [Start with this guide.](https://guides.github.com/overviews/mastering-markdown/)

#### HTML in Your Content

You shouldn't ever **need** to use HTML in your page. *But you can!*

This means that if more complex elements are needed on your page, you or someone on the dev-team can easily make them a reality.


### Page Settings

Each page can has some options that you're able to set like which icon should display in the corner or which sidebar should be displayed when that page is shown.

If you want to include settings **they should be the very first thing entered in your file**. They're set with `setting_name: setting_value`.

So, your file might look something like this:

```
icon: suitcase
sidebar: foundation

# The WDS Foundation was created to support people everywhere who want to start project aligned with the values of Community, Service and Adventure

We want you to apply now...
```

#### Current Available Page Settings

Name  | Available Values
------------- | -------------
icon  | globe, parachute, suitcase, pin, theater
sidebar  | Any sidebar file-name in `_sidebars`
photo_head | A comma-separated list of image URLs

### Setting a Sidebar

As mentioned above, you have total control over the sidebar that appears when your page is displayed.

Sidebars are created exactly as pages are except instead of creating a file in the `_content` folder, you'll be working in the `_sidebars` folder.

The filename should end in .md, just like a page, and the name you give the file is the value you'll use in your page settings to connect it.

Normally, your entire sidebar file is just a list of Markdown links, [like this example for the foundation](https://raw.githubusercontent.com/nickyhajal/world-domination-summit/master/_sidebars/foundation.md).

Those will automatically take on the style of the WDS site.

Of course, you can also use normal HTML in these files if you want something more specific.


## Content Assets

### Adding Decoration

The following are snippets of HTML you can copy and paste into your content to add some visual decoration.

Decoration | HTML
-------|------
Blue zig-zag separator | `<div class="zig-zags_blue"></div>`
Canvas solid-line separator | `<div class="line-canvas"></div>`
Register Button | `<a href="/register" class="register-banner"></a>`



