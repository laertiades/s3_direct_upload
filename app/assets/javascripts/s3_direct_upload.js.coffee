$ = jQuery

$.fn.S3Uploader = (options) ->

  # support multiple elements
  if @length > 1
    @each ->
      $(this).S3Uploader options

    return this

  $uploadForm = this

  settings =
    path: ''
    additional_data: null

  $.extend settings, options

  current_files = []

  setUploadForm = ->
  
    $uploadForm.bind 'fileuploadfinished', (e, data)=>
      content = build_content_object $uploadForm, data.files[0], data.result
      $uploadForm.trigger("s3_uploads_complete", [content])

    $uploadForm.bind 'fileuploadadd', (e, data)=> #called before the ui add method
      alert "added to #{current_files.length}"
      file = data.files[0]
      file.unique_id = Math.random().toString(36).substr(2,16)
      current_files.push data


    $uploadForm.bind 'fileuploaddone', (e, data)=>
      content = build_content_object $uploadForm, data.files[0], data.result

      callback_url = $uploadForm.data('callback-url')
      if callback_url
        content[$uploadForm.data('callback-param')] = content.url

        $.ajax
          type: $uploadForm.data('callback-method')
          url: callback_url
          data: content
          beforeSend: ( xhr, settings )       ->
            event = $.Event('ajax:beforeSend')
            $uploadForm.trigger(event, [xhr, settings])
            return event.result
          complete:   ( xhr, status )         ->
            event = $.Event('ajax:complete')
            $uploadForm.trigger(event, [xhr, status])
            return event.result
          success:    ( data, status, xhr )   ->
            event = $.Event('ajax:success')
            $uploadForm.trigger(event, [data, status, xhr])
            return event.result
          error:      ( xhr, status, error )  ->
            event = $.Event('ajax:error')
            $uploadForm.trigger(event, [xhr, status, error])
            return event.result
      $uploadForm.trigger("s3_upload_complete", [content])
      current_files.splice($.inArray(data, current_files), 1) # remove that element from the array
#       $uploadForm.trigger("s3_uploads_complete", [content]) unless current_files.length
      
    $uploadForm.fileupload
    
      dataType: 'xml' #response from s3
      singleFileUploads: true
      paramName: 'file'
#       maxNumberOfFiles: 1

      formData: (form) ->
        data = form.serializeArray()
        fileType = ""
        if "type" of @files[0]
          fileType = @files[0].type
        data.push
          name: "content-type"
          value: fileType

        key = $uploadForm.data("key")
          .replace('{timestamp}', new Date().getTime())
          .replace('{unique_id}', @files[0].unique_id)
          .replace('{extension}', @files[0].name.split('.').pop())

        # substitute upload timestamp and unique_id into key
        key_field = $.grep data, (n) ->
          n if n.name == "key"

        if key_field.length > 0
          key_field[0].value = settings.path + key

        # IE <= 9 doesn't have XHR2 hence it can't use formData
        # replace 'key' field to submit form
        unless 'FormData' of window
          $uploadForm.find("input[name='key']").val(settings.path + key)
        data
        
  build_content_object = ($uploadForm, file, result) ->
    content = {}
    if result # Use the S3 response to set the URL to avoid character encodings bugs
      content.url            = $(result).find("Location").text()
      content.filepath       = $('<a />').attr('href', content.url)[0].pathname
    else # IE <= 9 retu      rn a null result object so we use the file object instead
      domain                 = $uploadForm.attr('action')
      content.filepath       = $uploadForm.find('input[name=key]').val().replace('/${filename}', '')
      content.url            = domain + content.filepath + '/' + encodeURIComponent(file.name)

    content.filename         = file.name
    content.filesize         = file.size if 'size' of file
    content.lastModifiedDate = file.lastModifiedDate if 'lastModifiedDate' of file
    content.filetype         = file.type if 'type' of file
    content.unique_id        = file.unique_id if 'unique_id' of file
    content.relativePath     = build_relativePath(file) if has_relativePath(file)
    content = $.extend content, settings.additional_data if settings.additional_data
    content

  has_relativePath = (file) ->
    file.relativePath || file.webkitRelativePath

  build_relativePath = (file) ->
    file.relativePath || (file.webkitRelativePath.split("/")[0..-2].join("/") + "/" if file.webkitRelativePath)

  #public methods
  @initialize = ->
    # Save key for IE9 Fix
    $uploadForm.data("key", $uploadForm.find("input[name='key']").val())

    setUploadForm()
    this

  @path = (new_path) ->
    settings.path = new_path

  @additional_data = (new_data) ->
    settings.additional_data = new_data

  @initialize()
