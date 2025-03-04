# eval mbo design (if no y was passed by user)
# the following is done:
# 1) design is sanity checked a bit
# - do column names match par.set names + y names?
# - has the design been X-transformed?
# 2) if y-values are there, just log all points to optpath
# 3) if y-values are not there, eval points and log them to optpath

evalMBODesign.OptState = function(opt.state) {
  opt.problem = getOptStateOptProblem(opt.state)
  print('[opt.problem]')
  print(opt.problem)
  design = getOptProblemDesign(opt.problem)
  print('[design]')
  print(design)
  control = getOptProblemControl(opt.problem)
  print('[control]')
  print(control)
  
  par.set = getOptProblemParSet(opt.problem)
  print('[par.set]')
  print(par.set)
  pids = getParamIds(par.set, repeated = TRUE, with.nr = TRUE)
  print('[pids]')
  print(pids)
  y.name = control$y.name
  print('y.name')
  print(y.name)

  # get dummy "extras object" for init design
  extras = getExtras(n = nrow(design), prop = NULL, train.time = NA_real_, control = control)
  print('[extra]')
  # print(extras)

  # check that the provided design one seems ok
  # sanity check: are paramter values and colnames of design consistent?
  if (!setequal(setdiff(colnames(design), y.name), pids))
    stop("Column names of design 'design' must match names of parameters in 'par.set'!")

  # sanity check: do not allow transformed designs
  # if no trafo attribute provided we act on the assumption that the design is not transformed
  if (!hasAttributes(design, "trafo")) {
    design = setAttribute(design, "trafo", FALSE)
  } else {
    if (attr(design, "trafo")) {
      stop("Design must not be transformed!")
    }
  }

  design.x = dropNamed(design, y.name)
  # reorder + create list of x-points
  design.x = design.x[, pids, drop = FALSE]
  xs = dfRowsToList(design.x, par.set)
  print('[xs]')
  # print(xs)

  # either only log init design stuff to opt.path or eval y-values
  if (all(y.name %in% colnames(design))) {
    y = as.matrix(design[, y.name, drop = FALSE])
    lapply(seq_along(xs), function(i)
      addOptPathEl(getOptStateOptPath(opt.state), x = xs[[i]], y = y[i, ], dob = 0L,
        error.message = NA_character_, exec.time = NA_real_, extra = extras[[i]])
    )
  } else if (all(y.name %nin% colnames(design))) {
    showInfo(getOptProblemShowInfo(opt.problem), "Computing y column(s) for design. Not provided.")
    evalTargetFun.OptState(opt.state, xs, extras)
  } else {
    stop("Only part of y-values are provided. Don't know what to do - provide either all or none.")
  }
}
