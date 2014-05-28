###

###

jQuery.fn.scan 
	add: 
		id: 'attendee-answer'
		fnc: ->
			$t = $(this)
			name = $t.attr('name')
			question_id = $t.data('question_id')
			answers = ap.me?.get('answers')
			existing_answer = false
			for answer_obj in JSON.parse(answers)
				if answer_obj.question_id is question_id
					existing_answer = answer_obj.answer

			if existing_answer
				$t.val(existing_answer)

			changeFnc = ->
				val = $t.val()
				model_answers = JSON.parse(ap.me.get('answers'))
				set = false
				for i in [0..model_answers.length]
					if model_answers[i]?.question_id is question_id
						set = true
						model_answers[i].answer = val
				if not set
					new_answer = 
						answer: val
						question_id: question_id
					model_answers.push new_answer
				ap.me.set
					answers: JSON.stringify(model_answers)

			$t.change changeFnc
			$t.keyup changeFnc


