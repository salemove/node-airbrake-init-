R = require('ramda');

exports.initAirbrake = (opts) ->
  checkRequiredFields(opts)

  airbrake = require('airbrake').createClient(opts.projectId, opts.apiKey)

  airbrake.env = opts.env if opts.env
  airbrake.protocol = opts.protocol if opts.protocol
  airbrake.servicehost = opts.host if opts.host
  airbrake.blackListKeys = opts.blackListKeys if opts.blackListKeys
  airbrake.whiteListKeys = opts.whiteListKeys if opts.whiteListKeys
  airbrake.ignoredExceptions = opts.ignoredExceptions if opts.ignoredExceptions
  airbrake.addFilter(noticeFilter(opts))

  airbrake

exports.initWinstonAirbrake = (opts) ->
  checkRequiredFields(opts)

  if !(opts.env)
    opts.env = process.env.NODE_ENV || 'development'

  WinstonAirbrake = require('winston-airbrake').Airbrake
  winstonAirbrake = new WinstonAirbrake(opts)

  winstonAirbrake.airbrakeClient.whiteListKeys = opts.whiteListKeys if opts.whiteListKeys
  winstonAirbrake.airbrakeClient.blackListKeys = opts.blackListKeys if opts.blackListKeys
  winstonAirbrake.airbrakeClient.ignoredExceptions = opts.ignoredExceptions if opts.ignoredExceptions
  winstonAirbrake.airbrakeClient.addFilter(noticeFilter(opts))

  winstonAirbrake

noticeFilter = (opts) ->
  (notice) ->
    if notice.context.environment in opts.developmentEnvironments
      null
    else if opts.fileTransformation
      transformFile notice, opts.fileTransformation
    else
      notice

transformFile = (notice, fileTransformation) ->
  R.evolve({
    errors: R.map(R.evolve({
      backtrace: R.map(R.evolve({
        file: R.replace(fileTransformation.pattern, fileTransformation.replacement)
      }))
    }))
  }, notice)

checkRequiredFields = (opts) ->
  unless opts.apiKey
    throw "You must specify an Airbrake API key ('apiKey')"
  unless opts.whiteListKeys
    throw "You must specify a whitelist ('whiteListKeys')"
  unless opts.projectId
    throw "You must specify an Airbrake project ID ('projectId')"
