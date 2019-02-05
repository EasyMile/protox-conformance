# Protox.Conformance

## Conformance

The protox library (https://github.com/EasyMile/protox) has been tested using the conformance checker provided by Google.
Note that only the protobuf part is tested: as protox doesn't support JSON output, the corresponding tests are skipped.

Here's how to launch the conformance test:

* Get conformance-test-runner sources (https://github.com/google/protobuf/archive/v3.6.1.tar.gz)
* Compile conformance-test-runner:
  `tar xf protobuf-3.6.1.tar.gz && cd protobuf-3.6.1 && ./autogen.sh && ./configure && make -j && cd conformance && make -j`
* `mix protox.conformance --runner=/path/to/protobuf-3.6.1/conformance/conformance-test-runner`.
  A report will be generated in a file named `conformance_report.txt`.
  If everything's fine, the following text should be displayed (protobuf 3.6.1):

  ```
  CONFORMANCE TEST BEGIN ====================================

  CONFORMANCE SUITE PASSED: 388 successes, 431 skipped, 0 expected failures, 0 unexpected failures.
  ```

## Why a different repository?

`conformance-test-runner` needs an executable which reads and writes on standard i/o. Thus we wrote an escript that wraps protox.
