# S3DirectUpload
[demo](https://github.com/laertiades/fileuploader_demo)

Rails implementation of version 9.7.0 of jquery-file-upload for use with AWS S3.  Supports Basic-Plus-UI.  Uses Bootstrap, Sass, and Coffeescript.

Code extracted from Ryan Bates' [gallery-jquery-fileupload](https://github.com/railscasts/383-uploading-to-amazon-s3/tree/master/gallery-jquery-fileupload).

## Installation
Add these lines to your application's Gemfile:

    gem 'jquery-ui-rails'
    gem 'bootstrap-sass', '~> 3.2.0'
    gem 's3_direct_upload', :git => 'git://github.com/laertiades/s3_direct_upload.git'
    
**application.js** should look like:
```javascript
//= require jquery
//= require jquery-ui
//= require bootstrap-sprockets
//= require jquery_ujs
//= require jquery-fileupload
//= require s3_direct_upload
//= require_tree .
```

**application.scss** should look like:
```sass
@import "jquery-fileupload";
@import "bootstrap-sprockets";
@import "bootstrap";
@import "jquery-ui";
```

Then add a new initalizer with your AWS credentials:

**config/initializers/s3_direct_upload.rb**
```ruby
S3DirectUpload.config do |c|
  c.access_key_id = ""       # your access key id
  c.secret_access_key = ""   # your secret access key
  c.bucket = ""              # your bucket name
  c.region = nil             # region prefix of your bucket url. This is _required_ for the non-default AWS region, eg. "s3-eu-west-1"
  c.url = nil                # S3 API endpoint (optional), eg. "https://#{c.bucket}.s3.amazonaws.com/"
end
```

Make sure your AWS S3 CORS settings for your bucket look something like this:
```xml
<CORSConfiguration>
    <CORSRule>
        <AllowedOrigin>http://0.0.0.0:3000</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```
In production the AllowedOrigin key should be your domain.

## Usage
Create a new view that uses the form helper `s3_uploader_form`:
```ruby
<div class="container">
    <!-- The file upload form used as target for the file upload widget -->
    <%= s3_uploader_form callback_url: '/beats/create', callback_param: "model[image_url]", id: "s3-uploader" do %>
        <!-- Redirect browsers with JavaScript disabled to the origin page -->
        <noscript><input type="hidden" name="redirect" value="http://example.com"></noscript>
        <!-- The fileupload-buttonbar contains buttons to add/delete files and start/cancel the upload -->
        <div class="row fileupload-buttonbar">
            <div class="col-lg-7">
                <!-- The fileinput-button span is used to style the file input field as button -->
                <span class="btn btn-success fileinput-button">
                    <i class="glyphicon glyphicon-plus"></i>
                    <span>Add files...</span>
                    <input type="file" name="file" multiple>
                </span>
                <button type="submit" class="btn btn-primary start">
                    <i class="glyphicon glyphicon-upload"></i>
                    <span>Start upload</span>
                </button>
                <button type="reset" class="btn btn-warning cancel">
                    <i class="glyphicon glyphicon-ban-circle"></i>
                    <span>Cancel upload</span>
                </button>
                <button type="button" class="btn btn-danger delete">
                    <i class="glyphicon glyphicon-trash"></i>
                    <span>Delete</span>
                </button>
                <input type="checkbox" class="toggle">
                <!-- The global file processing state -->
                <span class="fileupload-process"></span>
            </div>
            <!-- The global progress state -->
            <div class="col-lg-5 fileupload-progress fade">
                <!-- The global progress bar -->
                <div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100">
                    <div class="progress-bar progress-bar-success" style="width:0%;"></div>
                </div>
                <!-- The extended global progress state -->
                <div class="progress-extended">&nbsp;</div>
            </div>
        </div>
        <!-- The table listing the files available for upload/download -->
        <table role="presentation" class="table table-striped"><tbody class="files"></tbody></table>
    <% end %>
    <br>
</div>
<!-- The template to display files available for upload -->
<script id="template-upload" type="text/x-tmpl">
{% for (var i=0, file; file=o.files[i]; i++) { %}
    <tr class="template-upload fade">
        <td>
            <span class="preview"></span>
        </td>
        <td>
            <p class="name">{%=file.name%}</p>
            <strong class="error text-danger"></strong>
        </td>
        <td>
            <p class="size">Processing...</p>
            <div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"><div class="progress-bar progress-bar-success" style="width:0%;"></div></div>
        </td>
        <td>
            {% if (!i && !o.options.autoUpload) { %}
                <button class="btn btn-primary start" disabled>
                    <i class="glyphicon glyphicon-upload"></i>
                    <span>Start</span>
                </button>
            {% } %}
            {% if (!i) { %}
                <button class="btn btn-warning cancel">
                    <i class="glyphicon glyphicon-ban-circle"></i>
                    <span>Cancel</span>
                </button>
            {% } %}
        </td>
    </tr>
{% } %}
</script>
<!-- The template to display files available for download -->
<script id="template-download" type="text/x-tmpl">
</script>
```

Note: Its required that the file input tag has a name attribute of 'file'.

Then in your application.js.coffee, call the S3Uploader jQuery plugin on the element you created above:
```coffeescript
jQuery ->
  $("#s3-uploader").S3Uploader()
```

## Options for form helper
* `callback_url:` No default. The url that is POST'd to after file is uploaded to S3. If you don't specify this option, no callback to the server will be made after the file has uploaded to S3.
* `callback_method:` Defaults to `POST`. Use PUT and remove the multiple option from your file field to update a model.
* `callback_param:` Defaults to `file`. Parameter key for the POST to `callback_url` the value will be the full s3 url of the file. If for example this is set to "model[image_url]" then the data posted would be `model[image_url] : http://bucketname.s3.amazonws.com/filename.ext`
* `key:` Defaults to `uploads/{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}`. It is the key, or filename used on s3. `{timestamp}` and `{unique_id}` are special substitution strings that will be populated by javascript with values for the current upload. `${filename}` is a special s3 string that will be populated with the original uploaded file name. Needs to be at least `"${filename}"`. It is highly recommended to use both `{unique_id}`, which will prevent collisions when uploading files with the same name (such as from a mobile device, where every photo is named image.jpg), and a server-generated random value such as `#{SecureRandom.hex}`, which adds further collision protection with other uploaders.
* `key_starts_with:` Defaults to `uploads/`. Constraint on the key on s3.  if you change the `key` option, make sure this starts with what you put there. If you set this as a blank string the upload path to s3 can be anything - not recommended!
* `acl:` Defaults to `public-read`. The AWS acl for files uploaded to s3.
* `max_file_size:` Defaults to `500.megabytes`. Maximum file size allowed.
* `id:` Optional html id for the form, its recommended that you give the form an id so you can reference with the jQuery plugin.
* `class:` Optional html class for the form.
* `data:` Optional html data attribute hash.
* `bucket:` Optional (defaults to bucket used in config).

### Example with all options
```ruby
<%= s3_uploader_form callback_url: model_url, 
                     callback_method: "POST", 
                     callback_param: "model[image_url]", 
                     key: "files/{timestamp}-{unique_id}-#{SecureRandom.hex}/${filename}", 
                     key_starts_with: "files/", 
                     acl: "public-read", 
                     max_file_size: 50.megabytes, 
                     id: "s3-uploader", 
                     class: "upload-form", 
                     data: {:key => :val} do %>
  <%= file_field_tag :file, multiple: true %>
<% end %>
```

### Example to persist the S3 url in your rails app
It is recommended that you persist the url that is sent via the POST request (to the url given to the `callback_url` option and as the key given in the `callback_param` option).

One way to do this is to make sure you have `resources model` in your routes file, and add a `s3_url` (or something similar) attribute to your model. Then make sure you have the create action in your controller for that model that saves the url from the callback_param.

You could then have your create action render a javascript file like this:
**create.js.erb**
```ruby
<% if @model.new_record? %>
  alert("Failed to upload model: <%= j @model.errors.full_messages.join(', ').html_safe %>");
<% else %>
  $("#container").append("<%= j render(@model) %>");
<% end %>
```
So that javascript code would be executed after the model instance is created, without a page refresh. See [@rbates's gallery-jquery-fileupload](https://github.com/railscasts/383-uploading-to-amazon-s3/tree/master/gallery-jquery-fileupload)) for an example of that method.

Note: the POST request to the rails app also includes the following parameters `filesize`, `filetype`, `filename` and `filepath`.

### Advanced Customizations
Reference the [API](https://github.com/blueimp/jQuery-File-Upload/wiki/API) for a myriad of options

## Options for S3Upload jQuery Plugin

* `path:` manual path for the files on your s3 bucket. Example: `path/to/my/files/on/s3`
  Note: Your path MUST start with the option you put in your form builder for `key_starts_with`, or else you will get S3 permission errors. The file path in your s3 bucket will be `path + key`.
* `additional_data:` You can send additional data to your rails app in the persistence POST request. This would be accessible in your params hash as  `params[:key][:value]`
  Example: `{key: value}`
* `fileuploadSettings:` Gives you access to the underlying fileupload API

### Example with multiple forms and single file input

```haml
#track-container
  %h3 Select Track
  = s3_uploader_form callback_url: '/beats/create', callback_param: "model[image_url]", id: "track-uploader" do
    %noscript
      %input{ :type => "hidden", :name => "redirect", :value => "http://blueimp.github.io/jQuery-File-Upload/" }
    %div.row.fileupload-buttonbar
      %div.col-lg-7
        %span.btn.btn-success.fileinput-button
          %i.glyphicon.glyphicon-plus
          %span Add files...
          %input{ :type => "file", :name => "file" }
        %button.btn.btn-primary.start{ :type => "submit" }
          %i.glyphicon.glyphicon-upload
          %span Start upload
        %span.fileupload-process
        %div.col-lg-5.fileupload-progress.fade
          %div.progress.progress-striped.active{ :role => "progressbar", "aria-valuemin" => "0", "aria-valuemax" => "100" }
            %div.progress-bar.progress-bar-success{ :style => "width:0%;" }
          %div.progress-extended &nbsp;
        %table.table.table-striped{ :role => "presentation" }
          %tbody.files
    %br
:plain
  <script id="track-upload" type="text/x-tmpl">
  {% for (var i=0, file; file=o.files[i]; i++) { %}
      <tr class="template-upload fade">
          <td><span class="preview"></span></td>
          <td>
              <p class="name">{%=file.name%}</p>
              <strong class="error text-danger"></strong>
          </td>
          <td>
              <p class="size">Processing...</p>
              <div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"><div class="progress-bar progress-bar-success" style="width:0%;"></div></div>
          </td>
          <td>
              {% if (!i && !o.options.autoUpload) { %}
                  <button class="btn btn-primary start" disabled>
                      <i class="glyphicon glyphicon-upload"></i>
                      <span>Start</span>
                  </button>
              {% } %}
              {% if (!i) { %}
                  <button class="btn btn-warning cancel">
                      <i class="glyphicon glyphicon-ban-circle"></i>
                      <span>Cancel</span>
                  </button>
              {% } %}
          </td>
      </tr>
  {% } %}
  </script>
#stems-container
  %h3 Select Stems
  = s3_uploader_form callback_url: '/beats/create', callback_param: "model[image_url]", id: "stems-uploader" do
    %noscript
      %input{ :type => "hidden", :name => "redirect", :value => "http://blueimp.github.io/jQuery-File-Upload/" }
    %div.row.fileupload-buttonbar
      %div.col-lg-7
        %span.btn.btn-success.fileinput-button
          %i.glyphicon.glyphicon-plus
          %span Add files...
          %input{ :type => "file", :name => "file", :multiple => true}
        %button.btn.btn-primary.start{ :type => "submit" }
          %i.glyphicon.glyphicon-upload
          %span Start upload
        %button.btn.btn-warning.cancel{ :type => "reset" }
          %i.glyphicon.glyphicon-ban-circle
          %span Cancel upload
        %span.fileupload-process
        %div.col-lg-5.fileupload-progress.fade
          %div.progress.progress-striped.active{ :role => "progressbar", "aria-valuemin" => "0", "aria-valuemax" => "100" }
            %div.progress-bar.progress-bar-success{ :style => "width:0%;" }
          %div.progress-extended &nbsp;
        %table.table.table-striped{ :role => "presentation" }
          %tbody.files
    %br
:plain
  <script id="stems-upload" type="text/x-tmpl">
  {% for (var i=0, file; file=o.files[i]; i++) { %}
      <tr class="template-upload fade">
          <td><span class="preview"></span></td>
          <td>
              <p class="name">{%=file.name%}</p>
              <strong class="error text-danger"></strong>
          </td>
          <td>
              <p class="size">Processing...</p>
              <div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"><div class="progress-bar progress-bar-success" style="width:0%;"></div></div>
          </td>
          <td>
              {% if (!i && !o.options.autoUpload) { %}
                  <button class="btn btn-primary start" disabled>
                      <i class="glyphicon glyphicon-upload"></i>
                      <span>Start</span>
                  </button>
              {% } %}
              {% if (!i) { %}
                  <button class="btn btn-warning cancel">
                      <i class="glyphicon glyphicon-ban-circle"></i>
                      <span>Cancel</span>
                  </button>
              {% } %}
          </td>
      </tr>
  {% } %}
  </script>
```

```coffeescript
$ ->
  form1 = $("#track-uploader").S3Uploader
    fileuploadSettings:
      uploadTemplateId: 'track-upload'
      downloadTemplateId: null
      url: '/stubs/create'
      maxNumberOfFiles: 1
  form1.bind 'fileuploadadd', (e, data)->
    $('tr.template-upload button.cancel').each ->
      $(this).click()
    $('tr.template-upload').remove()
    
  form2 = $("#stems-uploader").S3Uploader
    fileuploadSettings:
      uploadTemplateId: 'stems-upload'
      downloadTemplateId: null
      url: '/stubs/create'
```

### Public methods
You can change the settings on your form later on by accessing the jQuery instance:

```coffeescript
jQuery ->
  v = $("#myS3Uploader").S3Uploader()
  ...
  v.path("new/path/") #only works when the key_starts_with option is blank. Not recommended.
  v.additional_data("newdata")
```

### Javascript Events Hooks

#### Successfull upload
When a file has been successfully uploaded to S3, the `s3_upload_complete` is triggered on the form. A `content` object is passed along with the following attributes :

* `url`       The full URL to the uploaded file on S3.
* `filename`  The original name of the uploaded file.
* `filepath`  The path to the file (without the filename or domain)
* `filesize`  The size of the uploaded file.
* `filetype`  The type of the uploaded file.

This hook could be used for example to fill a form hidden field with the returned S3 url :
```coffeescript
$('#myS3Uploader').bind "s3_upload_complete", (e, content) ->
  $('#someHiddenField').val(content.url)
```

#### Rails AJAX Callbacks

In addition, the regular rails ajax callbacks will trigger on the form with regards to the POST to the server.

```coffeescript
$('#myS3Uploader').bind "ajax:success", (e, data) ->
  alert("server was notified of new file on S3; responded with '#{data}")
```

## Cleaning old uploads on S3
You may be processing the files upon upload and reuploading them to another
bucket or directory. If so you can remove the originali files by running a
rake task.

First, add the fog gem to your `Gemfile` and run `bundle`:
```ruby
  gem 'fog'
```

Then, run the rake task to delete uploads older than 2 days:
```
  $ rake s3_direct_upload:clean_remote_uploads
  Deleted file with key: "uploads/20121210T2139Z_03846cb0329b6a8eba481ec689135701/06 - PCR_RYA014-25.jpg"
  Deleted file with key: "uploads/20121210T2139Z_03846cb0329b6a8eba481ec689135701/05 - PCR_RYA014-24.jpg"
  $
```

Optionally customize the prefix used for cleaning (default is `uploads/#{2.days.ago.strftime('%Y%m%d')}`):
**config/initalizers/s3_direct_upload.rb**
```ruby
S3DirectUpload.config do |c|
  # ...
  c.prefix_to_clean = "my_path/#{1.week.ago.strftime('%y%m%d')}"
end
```

Alternately, if you'd prefer for S3 to delete your old uploads automatically, you can do
so by setting your bucket's
[Lifecycle Configuration](http://docs.aws.amazon.com/AmazonS3/latest/UG/LifecycleConfiguration.html).

## A note on IE support
IE file uploads are working but with a couple caveats.

* The before_add callback doesn't work.
* The progress bar doesn't work on IE.

But IE should still upload your files fine.


## Contributing / TODO
This is just a simple gem that only really provides some javascript and a form helper.
This gem could go all sorts of ways based on what people want and how people contribute.
Ideas:
* Get the Download template working
* More specs!
* More options to control file types, ability to batch upload.
* More convention over configuration on rails side
* Create generators.
* Model methods.
* Model method to delete files from s3

## Credit
This gem is forked from [Wayne Hoover](https://github.com/waynehoover/s3_direct_upload).
This gem is basically a small wrapper around code that [Ryan Bates](http://github.com/rbates) wrote for [Railscast#383](http://railscasts.com/episodes/383-uploading-to-amazon-s3). Most of the code in this gem was extracted from [gallery-jquery-fileupload](https://github.com/railscasts/383-uploading-to-amazon-s3/tree/master/gallery-jquery-fileupload).

Thank you Ryan Bates and Wayne Hoover

This code also uses the excellecnt [jQuery-File-Upload](https://github.com/blueimp/jQuery-File-Upload), which is included in this gem