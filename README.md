# Protox.Conformance

## Conformance

The protox library (https://github.com/EasyMile/protox) has been tested using the conformance checker provided by Google.
Note that only the protobuf part is tested: as protox doesn't support JSON
output, the corresponding tests are skipped.

Here's how to launch the conformance test:

* Get conformance-test-runner (https://github.com/google/protobuf/tree/master/conformance)
* `mix protox.conformance --runner=/path/to/conformance-test-runner`
  A report will be generated in a file named `conformance_report.txt`.
  If everything's fine, something like the following should be displayed:

  ```
  CONFORMANCE TEST BEGIN ====================================

  CONFORMANCE SUITE PASSED: 188 successes, 423 skipped, 0 expected failures, 0 unexpected failures.
  ```
  
## Why a different repository?

`conformance-test-runner` needs an executable which reads and writes on standard i/o. Thus we wrote an escript that wraps protox.
