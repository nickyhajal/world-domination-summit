_a = {}
_a.ajax = {}
_a.buf = []
_a.a = (action, data, callback = false, opts)->
	completed = false
	opts ?= {}
	opts.silent ?= false
	opts.timeout ?= 10000
	opts.errFnc ?= false
	silent = opts.silent
	if _a.ajax.onStart
		_a.ajax.onStart(opts)
	url = opts.url ? '/api/'+action
	if opts.buf
		_a.buffer.push
			action: action
			data: data
			time: new Date()
	# Make Ajax Request
	jQuery.ajax(
		url : url,
		data : data,
		xhrFields: {
       withCredentials: true
    },
    crossDomain: true,
		type : 'GET',
		dataType : 'jsonp',
		complete : (rsp, status)->
			# completed makes sure we don't run request twice (jquery jsonp bug)
			if not completed
				clearTimeout(_a.ajax.errTimeout);
				window.w = rsp
				if rsp
					text = rsp.responseText
					text = text.substr (text.indexOf '(')+1
					text = text.substr 0, (text.length-1)
					json = jQuery.parseJSON(text);
					if text.indexOf('"suc"') > -1
						_a.ajax.success(json.msg, opts);
						if callback
							callback(json);
					else
						if text.indexOf('"err"') > -1
							_a.ajax.error(json.msg, opts);
						else
							_a.ajax.mayBeError(opts);
						if opts.errFnc
							opts.errFnc();
				completed = true
	)
	###
_a.ajax.startLoading = ->
	_a.ajax.loading();
	_a.ajax.msgId ?=_a.ajax.msg.attr('id');
	_a.ajax.msg.remove();
	jQuery('body').append('<div/>').attr('id', _a.ajax.msgId).html('Loading...');
	_a.ajax.placeMsg();
		####
_a.ajax.loading = (inout)->
		if(!inout?)
			_a.ajax.msg.fadeIn();
			inout = false;
		else if !inout
			_a.ajax.msg.animate({opacity: .6}, _a.ajax.speed);
			inout = true;
		else
			_a.ajax.msg.animate({opacity: 1}, _a.ajax.speed)
			inout = false;
		_a.ajax.loadingTimeout = setTimeout(->
				_a.ajax.loading(inout)
		, _a.ajax.speed+10);      
_a.ajax.success = (msg, opts)->
		if _a.ajax.onSuccess
			_a.ajax.onSuccess(msg, opts)
_a.ajax.mayBeError = (opts)->
		if _a.onMayBeError
			_a.ajax.onMayBeError(opts);
			###
		clearTimeout(_a.ajax.loadingTimeout);
		_a.ajax.msg.stop().html(msg).css('background','#E5F7E5').animate({opacity: 1}, _a.ajax.speed);
		_a.ajax.placeMsg();
		_a.ajax.reset(1500);
		###
_a.ajax.error = (msg, opts)->
		if _a.ajax.onSuccess
			_a.ajax.onSuccess(msg, opts)
		###
		clearTimeout(_a.ajax.loadingTimeout);
		_a.ajax.msg.stop().html(msg).css('background', '#F8E3E3').animate({opacity: 1}, _a.ajax.speed);
		_a.ajax.placeMsg();
		_a.ajax.reset(5000);
		###
_a.ajax.reset = (s)->
		setTimeout(->
			_a.ajax.msg.fadeOut(750)
		,s);
_a.ajax.placeMsg = ->
		dims = jQuery(window).width();
		_a.ajax.msg.css('left', px((dims/2) - (_a.ajax.msg.outerWidth()/2)));
_a.ajax.speed = 750

if this._?
	this._.mixin(_a)
else 
	this._ = _a

this._.ajax = _a.ajax