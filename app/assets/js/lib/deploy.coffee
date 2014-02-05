_d = {}
_d.ari = (a, i)->
	return a[i];
	
_d.getForm = (id)->
	for form in document.forms
		if $(form).attr('id') is id
			return form
_d.formToJson = (id)->
	data = {};
	form = _d.getForm(id)
	for i in form.elements
		d($(i).attr('name'))
		d($(i).attr('name').length)
		if $(i).attr('name')? and $(i).attr('name').length
			data[$(i).attr('name')] = $(i).attr('value')
	return data;
_d.unSlug = (str)->
	str = str.split('-')
	for i, v of str
		str[i] = dpl.ucfirst(v)
	return str.join(' ')
_d.slugify = (str) ->
	from = "ąàáäâãćęèéëêìíïîłńòóöôõùúüûñçżź"
	to = "aaaaaaceeeeeiiiilnooooouuuunczz"
	regex = new RegExp(defaultToWhiteSpace(from), 'g');

	str = (''+str).toLowerCase();

	str = str.replace(regex, (ch)->
		index = from.indexOf(ch)
		return to.charAt(index) || '-';
	)
	return _.trim(str.replace(/[^\w\s-]/g, '').replace(/[-\s]+/g, '-'), '-')

_d.stript = (input, allowed) ->
	input = input.toString()
	allowed = (((allowed || "") + "").toLowerCase().match(/<[a-z][a-z0-9]*>/g) || []).join('') 
	tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi
	commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/gi
	return input.replace(commentsAndPhpTags, '').replace tags, ($0, $1) ->
		return if allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 then $0 else '' 
_d.toRad = (val) ->
	return val *  (Math.PI / 180)
_d.getDistance = (lat1, lon1, lat2, lon2) ->
  a = 6378137
  b = 6356752.314245
  f = 1 / 298.257223563
  L = _.toRad (lon2 - lon1)
  U1 = Math.atan((1 - f) * Math.tan(_.toRad(lat1)))
  U2 = Math.atan((1 - f) * Math.tan(_.toRad(lat2)))
  sinU1 = Math.sin(U1)
  cosU1 = Math.cos(U1)
  sinU2 = Math.sin(U2)
  cosU2 = Math.cos(U2)
  lambda = L
  lambdaP = undefined
  iterLimit = 100
  loop
    sinLambda = Math.sin(lambda)
    cosLambda = Math.cos(lambda)
    sinSigma = Math.sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) + (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda))
    return 0  if sinSigma is 0
    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
    sigma = Math.atan2(sinSigma, cosSigma)
    sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
    cosSqAlpha = 1 - sinAlpha * sinAlpha
    cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha
    cos2SigmaM = 0  if isNaN(cos2SigmaM)
    C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
    lambdaP = lambda
    lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))
    break unless Math.abs(lambda - lambdaP) > 1e-12 and --iterLimit > 0
  return NaN  if iterLimit is 0
  uSq = cosSqAlpha * (a * a - b * b) / (b * b)
  A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)))
  B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)))
  deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)))
  s = b * A * (sigma - deltaSigma)
  s

_d.nicetime = (start, end = false, just=60) ->
		# If no end is specified, use now
		if not _.isNumber(start)
			start = +start
		if not end
			end = +(new Date())
		diff = (end - start) / 1000
	
		# Output pretty times
		if(diff < just)
			return 'just now'
		else if(diff < 60)
			outDiff = Math.floor(diff)
			return outDiff+' '+(if outDiff==1 then 'second' else  'seconds')+ ' ago'
		else if(diff < 3600)
			outDiff = Math.floor(diff / 60)
			return outDiff+' '+(if outDiff==1 then 'minute' else  'minutes')+ ' ago'
		else if(diff < 86400)
			outDiff = Math.floor(diff / 3600)
			return  outDiff+' '+(if outDiff==1 then 'hour' else  'hours')+ ' ago'
		else if(diff > 86400)
			outDiff = Math.floor(diff / 86400)
			return  outDiff+' '+(if outDiff==1 then 'day' else  'days')+ ' ago'
		return false

defaultToWhiteSpace = (characters)->
	if (characters != null) 
		return '[' + _.escapeRegExp(''+characters) + ']';
	return '\\s';
_d.rgbToHex = (color)->
	if color.substr(0, 1) is '#' 
		return color
	 digits = /(.*?)rgb\((\d+), (\d+), (\d+)\)/.exec(color)
	 red = parseInt(digits[2])
	 green = parseInt(digits[3])
	 blue = parseInt(digits[4])
	 rgb = blue | (green << 8) | (red << 16)
	rgb = rgb.toString(16)
	while (rgb.length < 6) 
		rgb = '0' + rgb
	return '#' + rgb
_d.resizeStr = (str, size, append = '...')->
	if str.length > size
		str = str.substr(0, size) + append
	return str
_d.x = (str)->
	return str + 'px'
_.templateSettings = {
	  interpolate : /\{\{(.+?)\}\}/g
}

##
 # Turn a query string into an object
 ##
_d.query = (str = false, sep = '&') ->
	if typeof str == 'string'
		queryBits = str.split(sep)
		queries = {}
		for query in queryBits
			bits = query.split('=')
			queries[bits[0]] = bits[1]
		return queries
	return ''

_d.t = (template, data) ->
	html = unescape(ap.templates[template])
	return _.template(html, data)

_d.addSlashes = (str)->
	return (str+'').replace(/([\\"'])/g, "\\$1").replace(/\u0000/g, "\\0");
_d.stripSlashes = (str)->
	return (str+'').replace(/\\(.?)/g, (s, n1)->
		switch (n1) 
			when '\\'
				return '\\'
			when '0'
				return '\0'
			when ''
				return ''
			else
				return n1
	)
_d.money = (num, opts = false) ->
	opts = [] if not opts
	opts.presign ?= '$'
	opts.postsign ?= ''
	opts.div ?= 100
	return opts.presign + (( num * 1 ) / opts.div ).toFixed(2) + opts.postsign
_d.readys = {};
_d.whenReady = (id, fnc) ->
	_d.ready(id, fnc)
_d.ready = (id, fnc)->
	if _.isUndefined(_d.readys[id])
		_d.readys[id] = 
			ready: false
			fnc: false
	if _.isFunction(_d.readys[id].fnc)
		existing = _d.readys[id].fnc
		_d.readys[id].fnc = ->
			fnc()
			existing()
	else 
		_d.readys[id].fnc = ->
			fnc()
	if _d.readys[id].ready
		_d.doReady(id)
_d.nowReady = (id)->
	_d.isReady(id)
_d.isReady = (id)->
	if !_.isUndefined(_d.readys[id])
		_d.readys[id].ready = true;
		_d.doReady(id)
	else
		_d.readys[id] = 
			ready: true
			fnc: false
_d.doReady = (id)->
	if _d.readys[id]? and _d.readys[id].fnc? and _d.readys[id].fnc
		_d.readys[id].fnc();
		_d.readys[id].fnc = null;

_d.codeToCountry = (code, opts = {}) ->
	opts = _.defaults opts, 
		addComma: false
	countries = {
		AF: "Afghanistan"
		AX: "Aland Islands"
		AL: "Albania"
		DZ: "Algeria"
		AS: "American Samoa"
		AD: "Andorra"
		AO: "Angola"
		AI: "Anguilla"
		AQ: "Antarctica"
		AG: "Antigua and Barbuda"
		AR: "Argentina"
		AM: "Armenia"
		AW: "Aruba"
		AU: "Australia"
		AT: "Austria"
		AZ: "Azerbaijan"
		BS: "Bahamas"
		BH: "Bahrain"
		BD: "Bangladesh"
		BB: "Barbados"
		BY: "Belarus"
		BE: "Belgium"
		BZ: "Belize"
		BJ: "Benin"
		BM: "Bermuda"
		BT: "Bhutan"
		BO: "Bolivia"
		BA: "Bosnia and Herzegovina"
		BW: "Botswana"
		BV: "Bouvet Island"
		BR: "Brazil"
		IO: "British Indian Ocean Territory"
		BN: "Brunei"
		BG: "Bulgaria"
		BF: "Burkina Faso"
		BI: "Burundi"
		KH: "Cambodia"
		CM: "Cameroon"
		CA: "Canada"
		CV: "Cape Verde"
		KY: "Cayman Islands"
		CF: "Central African Republic"
		TD: "Chad"
		CL: "Chile"
		CN: "China"
		CX: "Christmas Island"
		CC: "Cocos Islands"
		CO: "Colombia"
		KM: "Comoros"
		CG: "Congo"
		CD: "Congo"
		CK:  "Cook Islands"
		CR: "Costa Rica"
		CI: "C™te d'Ivoire"
		HR: "Croatia"
		CU: "Cuba"
		CY: "Cyprus"
		CZ:  "Czech Republic"
		DK: "Denmark"
		DJ: "Djibouti"
		DM: "Dominica"
		DO: "Dominican Republic"
		EC: "Ecuador"
		EG: "Egypt"
		SV: "El Salvador"
		GQ: "Equatorial Guinea"
		ER: "Eritrea"
		EE: "Estonia"
		ET: "Ethiopia"
		FK: "Falkland Islands"
		FO: "Faroe Islands"
		FJ: "Fiji"
		FI: "Finland"
		FR: "France"
		GF:  "French Guiana"
		PF: "French Polynesia"
		TF: "French Southern Territories"
		GA: "Gabon"
		GM: "Gambia"
		GE: "Georgia"
		DE: "Germany"
		GH: "Ghana"
		GI: "Gibraltar"
		GR: "Greece"
		GL: "Greenland"
		GD: "Grenada"
		GP: "Guadeloupe"
		GU: "Guam"
		GT: "Guatemala"
		GG: "Guernsey"
		GN: "Guinea"
		GW: "Guinea-Bissau"
		GY: "Guyana"
		HT: "Haiti"
		HM: "Heard Island and McDonald Islands"
		HN: "Honduras"
		HK: "Hong Kong"
		HU: "Hungary"
		IS: "Iceland"
		IN: "India"
		ID: "Indonesia"
		IR: "Iran"
		IQ: "Iraq"
		IE: "Ireland"
		IM: "Isle of Man"
		IL: "Israel"
		IT: "Italy"
		JM: "Jamaica"
		JP: "Japan"
		JE:  "Jersey"
		JO: "Jordan"
		KZ: "Kazakhstan"
		KE: "Kenya"
		KI: "Kiribati"
		KW: "Kuwait"
		KG: "Kyrgyzstan"
		LA: "Laos"
		LV: "Latvia"
		LB: "Lebanon"
		LS: "Lesotho"
		LR: "Liberia"
		LY: "Libya"
		LI: "Liechtenstein"
		LT: "Lithuania"
		LU: "Luxembourg"
		MO: "Macao"
		MK: "Macedonia"
		MG: "Madagascar"
		MW: "Malawi"
		MY: "Malaysia"
		MV: "Maldives"
		ML: "Mali"
		MT: "Malta"
		MH: "Marshall Islands"
		MQ: "Martinique"
		MR: "Mauritania"
		MU: "Mauritius"
		YT: "Mayotte"
		MX: "Mexico"
		FM: "Micronesia"
		MD: "Moldova"
		MC: "Monaco"
		MN: "Mongolia"
		ME: "Montenegro"
		MS: "Montserrat"
		MA:  "Morocco"
		MZ: "Mozambique"
		MM: "Myanmar"
		NA: "Namibia"
		NR: "Nauru"
		NP: "Nepal"
		NL: "Netherlands"
		AN: "Netherlands Antilles"
		NC: "New Caledonia"
		NZ: "New Zealand"
		NI: "Nicaragua"
		NE:  "Niger"
		NG: "Nigeria"
		NU: "Niue"
		NF: "Norfolk Island"
		MP: "Northern Mariana Islands"
		KP: "North Korea"
		NO: "Norway"
		OM: "Oman"
		PK: "Pakistan"
		PW: "Palau"
		PS: "Palestinian Territories"
		PA: "Panama"
		PG: "Papua New Guinea"
		PY: "Paraguay"
		PE: "Peru"
		PH: "Philippines"
		PN: "Pitcairn"
		PL: "Poland"
		PT: "Portugal"
		PR: "Puerto Rico"
		QA: "Qatar"
		RE: "Reunion"
		RO: "Romania"
		RU: "Russia"
		RW: "Rwanda"
		SH: "Saint Helena"
		KN: "Saint Kitts and Nevis"
		LC: "Saint Lucia"
		PM: "Saint Pierre and Miquelon"
		VC: "Saint Vincent and the Grenadines"
		WS: "Samoa"
		SM: "San Marino"
		ST: "S‹o TomŽ and Pr’ncipe"
		SA: "Saudi Arabia"
		SN: "Senegal"
		RS: "Serbia"
		CS: "Serbia and Montenegro"
		SC: "Seychelles"
		SL: "Sierra Leone"
		SG: "Singapore"
		SK: "Slovakia"
		SI: "Slovenia"
		SB: "Solomon Islands"
		SO: "Somalia"
		ZA: "South Africa"
		GS: "South Georgia and the South Sandwich Islands"
		KR: "South Korea"
		ES: "Spain"
		LK: "Sri Lanka"
		SD: "Sudan"
		SR: "Suriname"
		SJ: "Svalbard and Jan Mayen"
		SZ: "Swaziland"
		SE: "Sweden"
		CH: "Switzerland"
		SY: "Syria"
		TW: "Taiwan"
		TJ: "Tajikistan"
		TZ: "Tanzania"
		TH: "Thailand"
		TL: "Timor-Leste"
		TG: "Togo"
		TK: "Tokelau"
		TO: "Tonga"
		TT: "Trinidad and Tobago"
		TN: "Tunisia"
		TR: "Turkey"
		TM: "Turkmenistan"
		TC: "Turks and Caicos Islands"
		TV: "Tuvalu"
		UG: "Uganda"
		UA: "Ukraine"
		AE: "United Arab Emirates"
		GB: "United Kingdom"
		US: "United States"
		UM: "United States minor outlying islands"
		UY: "Uruguay"
		UZ: "Uzbekistan"
		VU: "Vanuatu"
		VA: "Vatican City"
		VE: "Venezuela"
		VN: "Vietnam"
		VG: "Virgin Islands"
		VI: "Virgin Islands"
		WF: "Wallis and Futuna"
		EH: "Western Sahara"
		YE: "Yemen"
		ZM: "Zambia"
		ZW: "Zimbabwe"
	}
	str = ''
	if countries[code]?
		str = countries[code]
		if opts.addComma
			str = ', '+str
		
	return str

if this._?
	this._.mixin(_d)
else 
	this._ = _d

_.readys = _d.readys
