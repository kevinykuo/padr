source("library.R")

x_year  <- c(as.Date("2015-01-01"), as.Date("2018-01-01"))

x_month <- seq(as.Date("2015-01-01"), as.Date("2015-06-01"),
               by = "month")[c(1, 3, 4, 6)]

x_day   <- seq(as.Date("2015-01-01"), as.Date("2015-02-01"),
               by = "day") %>% sample(15) %>%
  c(as.Date("2015-01-01"), as.Date("2015-02-01")) %>% unique

x_hour  <- seq(
  as.POSIXct("2015-01-01 01:00:00"),
  as.POSIXct("2015-01-02 01:00:00"),
  by = "hour"
)[c(1, 25)]

x_min   <- seq(lubridate::ymd_hms("2015-01-01 00:00:00"),
               lubridate::ymd_hms("2015-01-01 00:59:00"), by = "min") %>%
  sample(15) %>%
  c(lubridate::ymd_hm("2015-01-01 00:00"),
    lubridate::ymd_hm("2015-01-01 00:59")) %>%
  unique


context("Test the pad function")

test_that("Correct error handling", {
  expect_error(pad(x_month %>% as.character))
  expect_error(pad(x_month %>% as.numeric))
  expect_error(pad(mtcars))
})

test_that("Gives warning when unordered", {
  expect_warning(pad(x_day %>% as.data.frame))
})

test_that("Pad works properly on data.table and tbl", {
  expect_equal(class(pad(data.table::data.table(x_year, 1)))[1], "data.table")
  expect_equal(class(pad(dplyr::data_frame(x_year, 1)))[1], "tbl_df")
})


context("pad gives correct output with one datetime value")

test_that('gives warning and same result when start_val and end_val are NULL', {
  x <- data.frame(tm = ymd(20160102))
  expect_warning(pad(x))
  suppressWarnings(expect_equal(pad(x), x))
})

test_that('gives correct output when end_val and/or start_val are specified, date', {
  x <- data.frame(tm = ymd(20160102))
  expect_equal(pad(x, start_val = ymd(20160101))$tm, c(ymd(20160101), x$tm))
  expect_equal(pad(x, end_val = ymd(20160104), interval = "day")$tm,
               c(x$tm, ymd(20160103), ymd(20160104)))
  expect_equal(pad(x, start_val = ymd(20160101), end_val = ymd(20160104))$tm,
               seq(ymd(20160101), by = 'day', length.out = 4))
})

test_that('gives correct output when end_val and/or start_val are specified, posix', {
  x <- data.frame(tm = ymd_h('20160102 16'))
  s_val <- ymd_h('20160101 16')
  e_val <- ymd_h('20160104 16')
  compare <- seq(s_val, by = 'day', length.out = 4)
  expect_equal(pad(x, start_val = s_val)$tm, compare[1:2])
  expect_equal(pad(x, end_val = e_val, interval = "day")$tm, compare[2:4])
  expect_equal(pad(x, start_val = s_val, end_val = e_val)$tm, compare)
})

context("pad_single and pad_multiple, addtions to padr")

test_that("pad_single gives correct output, with no groups", {
  mnths <- seq(ymd(20160101), length.out = 5, by = 'month')
  x <- data.frame(m = mnths[c(2, 4)])
  expect_equal( pad_single(x, "month")$m, mnths[2:4])
  expect_equal( pad_single(x, start_val = mnths[1])$m, mnths[1:4])
  expect_equal( pad_single(x, end_val = mnths[5])$m, mnths[2:5])
})

test_that("pad_multiple pads correctly with one group var", {
  mnths <- seq(ymd(20160101), length.out = 5, by = 'month')
  x <- data.frame(m = rep( mnths[c(2, 4)], 2), g = letters[c(1, 1, 2, 2)])
  expect_equal( pad_multiple(x, group = 'g', interval = "month")$m, rep(mnths[2:4], 2) )
  expect_equal( pad_multiple(x, group = 'g', start_val = mnths[1])$m, rep(mnths[1:4], 2) )
  expect_equal( pad_multiple(x, group = 'g', end_val = mnths[5])$m, rep(mnths[2:5], 2) )
})

test_that("pad_multiple pads correctly with two group vars", {
  mnths <- seq(ymd(20160101), length.out = 5, by = 'month')
  x <- data.frame(m  = rep( mnths[c(2, 4)], 4),
                  g1 = letters[rep(1:2, each = 4)],
                  g2 = letters[rep(5:8, each = 2)])
  expect_equal( pad_multiple(x, group = c('g1', 'g2'), interval = "months")$m, rep(mnths[2:4], 4) )
  expect_equal( pad_multiple(x, group = c('g1', 'g2'), start_val = mnths[1])$m, rep(mnths[1:4], 4) )
  expect_equal( pad_multiple(x, group = c('g1', 'g2'), end_val = mnths[5])$m, rep(mnths[2:5], 4) )
})

test_that("the by arguments works, both in pad and pad_single", {
  one_var <- data.frame(x_year = x_year, val = 1)
  two_var <- one_var; two_var$x_year2 <- two_var$x_year
  one_var_grps <- rbind(one_var, one_var)
  one_var_grps$grp <- rep(letters[1:2], each = 2)
  two_var_grps <- rbind(two_var, two_var)
  two_var_grps$grp <- rep(letters[1:2], each = 2)
  check_val <- seq( ymd(20150101), length.out = 4, by = 'year')

  expect_equal( pad(one_var, by = "x_year", interval = "year")$x_year, check_val)
  expect_equal( pad_single(one_var, by = "x_year",  interval = "year")$x_year, check_val)
  expect_equal( pad(one_var_grps, by = "x_year", group = 'grp',  interval = "year")$x_year,
                rep(check_val, 2) )
  expect_equal( pad_multiple(one_var_grps, by = "x_year", group = 'grp',
                             interval = "year")$x_year, rep(check_val, 2) )

  expect_equal( pad(two_var, "year", by = "x_year")$x_year, check_val)
  expect_equal( pad_single(two_var, "year", by = "x_year")$x_year, check_val)
  expect_equal( pad(two_var_grps, "year", by = "x_year", group = 'grp')$x_year,
                rep(check_val, 2) )
  expect_equal( pad_multiple(two_var_grps, "year", by = "x_year", group = 'grp')$x_year,
                rep(check_val, 2) )
})


context("pad integration tests")
test_that("Pad gives correct results", {
  expect_equal(pad(data.frame(x_year, 1), "year") %>% nrow, 4)
  expect_equal(pad(data.frame(x_year, 1), "year", end_val = as.Date("2021-01-01")) %>%
                 nrow, 7)
  expect_equal(pad(data.frame(x_year, 1), "year", start_val = as.Date("2012-01-01")) %>%
                 nrow, 7)
  expect_equal(pad(data.frame(x_year, 1), interval = "month") %>% nrow, 37)
  expect_equal(pad(data.frame(x_month, 1)) %>% nrow, 6)
  expect_equal(suppressWarnings(pad(data.frame(x_day, 1))) %>% nrow, 32)
  expect_equal(pad(data.frame(x_hour, 1)) %>% nrow, 2)
  expect_equal(pad(data.frame(x_hour, 1), interval = "hour") %>% nrow, 25)
  expect_equal(suppressWarnings(pad(data.frame(x_min, 1))) %>% nrow, 60)
})
