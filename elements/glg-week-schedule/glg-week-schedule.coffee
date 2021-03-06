###
  This is a schedule to display information on a given interval. Also,
  includes functions to determine usage and array disection.

  meeting.highlight
  @demo elements/glg-week-schedule/demo/index.html
###

moment = require('moment')
_ = require('lodash')

Polymer(
  is: 'glg-week-schedule',

  properties: {
    week: {
      type: Number,
      value: () -> return moment().week()
      notify: true
    },
    month: {
      type: Number,
      value: () -> return moment().month()
      notify: true
    },
    year: {
      type: Number,
      value: () -> return moment().year()
      notify: true
    },
    meetings: {
      type: Array,
      value: () -> return []
    },
    loading: {
      type: Boolean,
      value: () -> return false
    }
  },
  listeners: {
    'minusWeek.click': 'minusWeek',
    'plusWeek.click': 'plusWeek'

  }, 
  observers: [
    'meetingsChanged(meetings)'
  ],  

  ready: ->
    @dayArr = [0..6]
    @hourArr = [0..23]
    @height = 0
    @week = moment().month(@month).week()
    @monthMeetings = []

  attached: ->
    @async(() ->
      @height = parseInt(window.getComputedStyle(document.getElementById(moment().hour())).height) / (60 / moment().minute())
    ,1)

  meetingsChanged: (meetings) ->
    return if !meetings.length

    @monthMeetings = _.flatten meetings
    _.each @monthMeetings, (meeting) =>
      meeting.date = moment(meeting.date).week(moment().week())
      meeting.end = moment(meeting.end).week(moment().week())

    if @monthMeetings.length
      updatedMeetings = []
      _.each @monthMeetings, (meeting) =>
        meeting.OtherMeetingsDuringTimeFrame = _.filter(meetings, (otherMeeting) -> 
          moment(meeting.date) <= moment(otherMeeting.end) && moment(meeting.end) >= moment(otherMeeting.date)).length
        updatedMeetings.push(meeting)
      @updatedMeetings = updatedMeetings
      @filterMeetings()

  filterMeetings: () ->
    @updatedMeetings = _.filter @monthMeetings, (meeting) =>
      moment(meeting.date).week() == @week

  minusWeek: () ->
    if !@loading
      @week = @week - 1
      @month = moment().week(@week).month()
      @year = moment().week(@week).year()
      @filterMeetings()

  plusWeek: () ->
    if !@loading
      @week = @week + 1
      @month = moment().week(@week).month()
      @year = moment().week(@week).year()
      @filterMeetings()

  getMonth: (week) ->
    moment().week(@week).format("MMMM")

  getRealDate: (dayPos) ->
    moment().week(@week).day(dayPos)

  getRealHour: (hourPos) ->
    moment().week(@week).hour(hourPos)

  getHourLabel: (hourPos, week) ->
    @getRealHour(hourPos).format("h A")

  getDateLabelOne: (dayPos, week) ->
    moment(@getRealDate(dayPos)).format("ddd")

  getDateLabelTwo: (dayPos) ->
    moment(@getRealDate(dayPos)).format("D")

  getDayClasses: (dayPos, week) ->
    if moment().isSame(@getRealDate(dayPos)) then "currentDayLabel" else ""

  isCurrentHour: (hourPos) ->
    @getRealHour(hourPos).hour() == moment().hour()

  getWeekDayClasses: (dayPos) ->
    weekend = if dayPos == 0 || dayPos == 6 then " weekend" else ""
    current = if moment().isSame(@getRealDate(dayPos)) then " current" else ""
    endweek = if dayPos == 6 then " endweek" else ""
    "week-hour weekday#{weekend}#{current}#{endweek}"

  getMeetingStyles: (hourPos, dayPos, meetings) ->
    placeholders = @getPlaceholderMeetings(hourPos, dayPos, meetings)
    if placeholders
      width = 100/(placeholders.length +  @getMeetingsDuring(hourPos, dayPos, meetings).length)
      "width:#{width}%"

  getTLPadding: (height) ->
    "padding-top: #{@height}px"

  getWeekHourId: (dayPos, hourPos) ->
    "#{hourPos},#{dayPos}"

  getTitleClass: (meeting) ->
    highlight = if !meeting.highlight then ' title-highlight' else ''
    "title#{highlight}"

  getMeetings: (dayPos, hourPos, meetings) ->
    realHour = @getRealHour(hourPos)
    meetingArr = _.map(meetings,(meeting) -> {'meetingId': meeting.id, 'day': moment(meeting.date).day(), 'hour': moment(meeting.date).hour(), 'minute': moment(meeting.date).minute(), 'title': meeting.title, 'type': meeting.type, 'end': meeting.end})
    meetingArr = _.filter meetingArr ,(meeting) -> meeting.day == dayPos && meeting.hour == hourPos
    meetingArr = _.sortByAll(meetingArr, ['hour','minute'])

  getMeetingsDuring: (hourPos, dayPos, meetings) ->
    _.filter meetings, (meeting) -> moment(meeting.date).hour() <= hourPos <= moment(meeting.end).hour() && dayPos == moment(meeting.date).day()

  getByHour: (hourPos, meetings) ->
    realHour = @getRealHour(hourPos)
    meetingArr = _.map meetings,(meeting) -> {'meetingId': meeting.id,'hour': moment(meeting.date).format("H"), 'minute': moment(meeting.date).format("m"), 'day': moment(meeting.date).day()}
    meetingArr = _.filter meetingArr ,(meeting) -> meeting.hour == realHour.format("H")
    meetingArr = _.sortBy(meetingArr, 'minute')
    meetingArr

  filterByDay: (meetingArr, dayPos) ->
    meetingArr = _.filter meetingArr ,(meeting) -> meeting.day == dayPos
    meetingArr
  
  getPlaceholderMeetings: (hourPos, dayPos, meetings) ->
    meetingArr = @getMeetingsDuring(hourPos, dayPos, meetings)
    return [] if !meetingArr.length || meetingArr[0].OtherMeetingsDuringTimeFrame - meetingArr.length <= 0
    return [0..meetingArr[0].OtherMeetingsDuringTimeFrame - meetingArr.length - 1]
   
  isMeetingStart: (hourPos, meeting) ->
    moment(meeting.date).hour() == hourPos

)