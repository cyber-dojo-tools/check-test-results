# check-test-results

Checks Ruby test results and coverage metrics.
Eg [https://github.com/cyber-dojo/differ/blob/master/sh/test_in_containers.sh#L89](https://github.com/cyber-dojo/differ/blob/master/sh/test_in_containers.sh#L89)

Relies on input files:

- coverage.json
As produced by [SimpleCov::Formatter::JSONFormatter](https://github.com/cyber-dojo/differ/blob/master/test/lib/simplecov_json.rb)
installed in [coverage.rb](https://github.com/cyber-dojo/differ/blob/master/test/lib/coverage.rb)
which is the actual metrics values for the test run being checked.
Eg
<pre>
{
  "timestamp": 1679572944,
  "command_name": "Minitest",
  "groups": {
    "app": {
      "lines": {
        "total": 352,
        "covered": 352,
        "missed": 0
      },
      "branches": {
        "total": 60,
        "covered": 59,
        "missed": 1
      }
    },
    "test": {
      "lines": {
        "total": 528,
        "covered": 528,
        "missed": 0
      },
      "branches": {
        "total": 0,
        "covered": 0,
        "missed": 0
      }
    }
  }
}
</pre>

- [metrics.rb](https://github.com/cyber-dojo/differ/blob/main/test/lib/metrics.rb)
Which is the metrics limits to check the previous coverage.json results against.
Eg
<pre>
MAX = {
  failures: 0,
  errors: 0,
  warnings: 1,
  skips: 0,

  duration: 50,

  app: {
    lines: {
      total: 353,
      missed: 0
    },
    branches: {
      total: 60,
      missed: 1
    }
  },

  test: {
    lines: {
      total: 528,
      missed: 0
    },
    branches: {
      total: 0,
      missed: 0
    }
  }
}.freeze
</pre>

