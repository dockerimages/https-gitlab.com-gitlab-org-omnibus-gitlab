# Adding new tests to GitLab Health Checks

* Health checks are written using [Serverspec](http://serverspec.org/), which is based on [RSpec](http://rspec.info)
* The Serverspec documentation is written using `should` syntax, our examples should use `expect`. See the note in [Resource Types](http://burtlo.github.io/serverspec.github.io/resource_types.html) for the reasons why.
* If there does not exist an appropriate file under `files/health_checks` already, create a new one with the filename ending in `_spec.rb`.
* Be sure each spec file includes `require 'spec_helper'`
* The test name should be an indication of why the test is failing. I.E. if we expect an instance to foo, then the test should look like
   ```ruby
   describe OBJECT do
     it 'does not FOO' do
       expect(something) to be(FOO)
     end
   end
   ```
   The output on a failure will be
   ```sh
   There was an issue detected:
   ...
   OBJECT does not FOO
   ...
   ```
