module CI
  class Jobs
    DISTROS = {
      'AmazonLinux-2' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: true,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'CentOS-7' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: false,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'CentOS-8' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: true,
        nightly_upload: false,
        auto_deploy: false,
        fips: true
      },
      'Debian-9' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: false,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'Debian-10' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: true,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'Debian-11' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: true,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'OpenSUSE-15.3' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: true,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'Ubuntu-16.04' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: false,
        nightly_upload: true,
        auto_deploy: true,
        fips: false
      },
      'Ubuntu-18.04' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: false,
        nightly_upload: true,
        auto_deploy: true,
        fips: true
      },
      'Ubuntu-20.04' => {
        tester_image: '',
        builder_image: '',
        run_tests: true,
        ce: true,
        ee: true,
        arm: true,
        nightly_upload: true,
        auto_deploy: true,
        fips: true
      },
      'SLES-12.5' => {
        tester_image: '',
        builder_image: '',
        run_tests: false,
        ce: false,
        ee: true,
        arm: false,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'SLES-15.2' => {
        tester_image: '',
        builder_image: '',
        run_tests: false,
        ce: false,
        ee: true,
        arm: false,
        nightly_upload: false,
        auto_deploy: false,
        fips: false
      },
      'Raspberry-Pi-2-Buster' => {
        tester_image: '',
        builder_image: '',
        run_tests: false,
        ce: true,
        ee: false,
        arm: false,
        auto_deploy: false,
        fips: false
      }
    }.freeze

    class << self
      def list
        jobs = {}
        jobs.merge!(check_jobs)
        jobs.merge!(prepare_jobs)
        jobs.merge!(test_jobs)
        jobs.merge!(post_test_jobs)
        jobs.merge!(review_jobs)
        jobs.merge!(package_and_qa_jobs)
        jobs.merge!(package_jobs)
        jobs.merge!(image_jobs)
        jobs.merge!(other_release_jobs)
        jobs.merge!(other_jobs)

        jobs
      end

      def testable_distros
        DISTROS.select { |os, details| details[:run_tests] }
      end

      def check_jobs
        {
          'danger-review' => {
            stage: 'check',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
            ]
          },
          'rubocop' => {
            stage: 'check',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
            ]
          },
          'yard' => {
            stage: 'check',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
            ]
          },
          'docs-lint markdown' => {
            stage: 'check',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
              :canonical_docs_pipeline,
              :fork_docs_pipeline,
            ]
          },
          'docs-lint links' => {
            stage: 'check',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
              :canonical_docs_pipeline,
              :fork_docs_pipeline,
            ]
          },
          'check-for-sha-in-mirror' => {
            stage: 'check',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
            ]
          },
          'validate-packer-changes' => {
            stage: 'check',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
            ]
          }
        }
      end

      def prepare_jobs
        result = {
          'generate-facts' => {
            stage: 'prepare',
            needs: [],
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
              :dev_ce_branch_pipeline,
              :dev_ee_branch_pipeline,
              :dev_ce_nightly_pipeline,
              :dev_ee_nightly_pipeline,
              :dev_ce_rc_pipeline,
              :dev_ee_rc_pipeline,
              :dev_ce_tag_pipeline,
              :dev_ee_tag_pipeline,
            ],
          },
          'fetch-assets' => {
            stage: 'prepare',
            needs: [],
            script: ['echo "Hello World"'],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
              :dev_ce_branch_pipeline,
              :dev_ce_branch_pipeline_by_schedule,
              :dev_ce_nightly_pipeline,
              :dev_ee_branch_pipeline,
              :dev_ee_branch_pipeline_by_schedule,
              :dev_ee_nightly_pipeline,
              :dev_auto_deploy_pipeline,
              :dev_ce_rc_pipeline,
              :dev_ee_rc_pipeline,
              :dev_ce_tag_pipeline,
              :dev_ee_tag_pipeline,
            ],
          },
          'create_omnibus_manifest' => {
            stage: 'prepare',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_dependency_scanning_pipeline_by_schedule,
            ]
          }
        }

        result.merge!(knapsack_jobs)

        result
      end

      def test_jobs
        result = {
          'build library specs' => {
            stage: 'test',
            script: ['echo "Hello World"'],
            needs: ['rubocop'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
            ]
          }
        }
        result.merge!(spec_jobs)

        result
      end

      def post_test_jobs
        {
          'update-knapsack' => {
            stage: 'post-test',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :fork_ce_branch_pipeline,
              :fork_ee_branch_pipeline,
            ]
          }
        }
      end

      def review_jobs
        {
          'review-docs-cleanup' => {
            stage: 'review',
            script: ['echo "Hello World"'],
            needs: [],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :canonical_docs_pipeline,
            ]
          },
          'review-docs-deploy' => {
            stage: 'review',
            script: ['echo "Hello World"'],
            needs: [],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
              :canonical_docs_pipeline,
            ]
          }
        }
      end

      def package_and_qa_jobs
        {
          'Trigger:ce-package' => {
            stage: 'package-and-qa',
            script: ['echo "Hello World"'],
            needs: [],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
            ]
          },
          'Trigger:ee-package' => {
            stage: 'package-and-qa',
            script: ['echo "Hello World"'],
            needs: [],
            pipeline_types: [
              :canonical_ce_branch_pipeline,
              :canonical_ee_branch_pipeline,
            ]
          },
          'Trigger:package' => {
            stage: 'package',
            script: ['echo "Hello World"'],
            needs: [
              'fetch-assets',
              'generate-facts'
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'Trigger:package:fips' => {
            stage: 'package',
            script: ['echo "Hello World"'],
            needs: [
              'fetch-assets',
              'generate-facts'
            ],
            pipeline_types: [
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'Trigger:docker' => {
            stage: 'image',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:package'
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'Trigger:QA-docker' => {
            stage: 'image',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:package'
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'package_size_check' => {
            stage: 'test',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:package'
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'qa' => {
            stage: 'test',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:docker',
              'Trigger:QA-docker',
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'letsencrypt-test' => {
            stage: 'test',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:docker',
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'RAT' => {
            stage: 'test',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:package',
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'RAT:FIPS' => {
            stage: 'test',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:package:fips',
            ],
            pipeline_types: [
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          },
          'GET:Geo' => {
            stage: 'test',
            script: ['echo "Hello World"'],
            needs: [
              'Trigger:package',
            ],
            pipeline_types: [
              :mirror_ce_branch_pipeline_by_trigger,
              :mirror_ee_branch_pipeline_by_trigger,
            ]
          }
        }
      end

      def package_jobs # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        editions = [:ce, :ee]
        variations = [nil, :arm, :fips]

        {}.tap do |result|
          DISTROS.select do |os, details|
            variations.each do |variation|
              tag_job_name = os

              if variation
                tag_job_name = "#{os}-#{variation}"
                next unless details[variation]
              end

              branch_job_name = "#{tag_job_name}-branch"
              staging_upload_job_name = "#{tag_job_name}-staging-upload"
              release_job_name = "#{tag_job_name}-release"

              # Branch build
              result[branch_job_name] = {
                stage: 'package',
                script: ['echo "Hello World"'],
                needs: [
                  'fetch-assets',
                  'generate-facts'
                ],
                pipeline_types: [].tap do |types|
                  editions.each do |edition|
                    next unless details[edition]
                    next if variation == :fips && edition == :ce

                    types << "dev_#{edition}_branch_pipeline".to_sym
                    types << "dev_#{edition}_nightly_pipeline".to_sym
                  end
                end
              }

              # Tag build
              result[tag_job_name] = {
                stage: 'package',
                script: ['echo "Hello World"'],
                needs: [
                  'fetch-assets',
                  'generate-facts'
                ],
                pipeline_types: [].tap do |types|
                  editions.each do |edition|
                    next unless details[edition]
                    next if variation == :fips && edition == :ce

                    types << "dev_#{edition}_rc_pipeline".to_sym
                    types << "dev_#{edition}_tag_pipeline".to_sym
                  end
                end
              }

              # Nightly upload
              if details[:nightly_upload] && variation.nil?
                nightly_upload_job_name = "#{tag_job_name}-nightly-upload"
                result[nightly_upload_job_name] = {
                  stage: 'staging-upload',
                  script: ['echo "Hello World"'],
                  needs: [
                    'fetch-assets',
                    'generate-facts',
                    branch_job_name,
                  ],
                  pipeline_types: [].tap do |types|
                    editions.each do |edition|
                      next if variation == :fips && edition == :ce

                      types << "dev_#{edition}_nightly_pipeline".to_sym if details[edition]
                    end
                  end
                }
              end

              # Staging upload
              result[staging_upload_job_name] = {
                stage: 'staging-upload',
                script: ['echo "Hello World"'],
                needs: [
                  'fetch-assets',
                  'generate-facts',
                  tag_job_name,
                ],
                pipeline_types: [].tap do |types|
                  editions.each do |edition|
                    next unless details[edition]
                    next if variation == :fips && edition == :ce

                    types << "dev_#{edition}_rc_pipeline".to_sym
                    types << "dev_#{edition}_tag_pipeline".to_sym
                  end
                end
              }

              # Release
              result[release_job_name] = {
                stage: 'release',
                script: ['echo "Hello World"'],
                needs: [
                  'fetch-assets',
                  'generate-facts',
                  tag_job_name,
                ],
                pipeline_types: [].tap do |types|
                  editions.each do |edition|
                    next unless details[edition]
                    next if variation == :fips && edition == :ce

                    types << "dev_#{edition}_rc_pipeline".to_sym
                    types << "dev_#{edition}_tag_pipeline".to_sym
                  end
                end
              }
            end
          end
        end
      end

      def image_jobs
        {}.tap do |result|
          %w[Docker Docker-QA].each do |image|
            # Branch pipeline
            result["#{image}-branch"] = {
              stage: 'image',
              script: ['echo "Hello World"'],
              needs: [
                'Ubuntu-20.04-branch',
                'generate-facts',
              ],
              pipeline_types: [
                :dev_ce_branch_pipeline,
                :dev_ee_branch_pipeline,
                :dev_ce_nightly_pipeline,
                :dev_ee_nightly_pipeline,
              ]
            }

            # Tag build
            result[image.to_s] = {
              stage: 'image',
              script: ['echo "Hello World"'],
              needs: [
                'Ubuntu-20.04',
                'generate-facts',
              ],
              pipeline_types: [
                :dev_ce_rc_pipeline,
                :dev_ee_rc_pipeline,
                :dev_ce_tag_pipeline,
                :dev_ee_tag_pipeline,
                :dev_auto_deploy_pipeline
              ]
            }

            # Docker release
            result["#{image}-release"] = {
              stage: 'release',
              script: ['echo "Hello World"'],
              needs: [
                'generate-facts',
                image
              ],
              pipeline_types: [
                :dev_ce_rc_pipeline,
                :dev_ee_rc_pipeline,
                :dev_ce_tag_pipeline,
                :dev_ee_tag_pipeline,
              ]
            }
          end
        end
      end

      def other_release_jobs
        {
          'AWS' => {
            stage: 'release',
            script: ['echo "Hello World"'],
            needs: [
              'Ubuntu-20.04'
            ],
            pipeline_types: [
              :dev_ce_tag_pipeline,
              :dev_ee_tag_pipeline,
            ]
          },
          'AWS-arm64' => {
            stage: 'release',
            script: ['echo "Hello World"'],
            needs: [
              'Ubuntu-20.04-arm'
            ],
            pipeline_types: [
              :dev_ce_tag_pipeline,
              :dev_ee_tag_pipeline,
            ]
          },
          'AWS-Premium' => {
            stage: 'release',
            script: ['echo "Hello World"'],
            needs: [
              'Ubuntu-20.04'
            ],
            pipeline_types: [
              :dev_ee_tag_pipeline,
            ]
          },
          'AWS-Ultimate' => {
            stage: 'release',
            script: ['echo "Hello World"'],
            needs: [
              'Ubuntu-20.04'
            ],
            pipeline_types: [
              :dev_ee_tag_pipeline,
            ]
          },
          'AWS-CE-Release' => {
            stage: 'release',
            script: ['echo "Hello World"'],
            needs: [
              'AWS'
            ],
            pipeline_types: [
              :dev_ce_tag_pipeline,
            ]
          },
          'AWS-EE-Premium-Release' => {
            stage: 'release',
            script: ['echo "Hello World"'],
            needs: [
              'AWS-Premium'
            ],
            pipeline_types: [
              :dev_ee_tag_pipeline,
            ]
          },
          'AWS-EE-Ultimate-Release' => {
            stage: 'release',
            script: ['echo "Hello World"'],
            needs: [
              'AWS-Ultimate'
            ],
            pipeline_types: [
              :dev_ee_tag_pipeline,
            ]
          }
        }
      end

      def other_jobs
        {
          'pages' => {
            stage: 'other',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_ce_branch_pipeline_by_schedule,
            ]
          },
          'license_upload' => {
            stage: 'other',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :dev_ce_tag_pipeline,
              :dev_ee_tag_pipeline,
            ]
          },
          'update-gems-cache' => {
            stage: 'prepare',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_cache_update_pipeline_by_schedule,
              :mirror_cache_update_pipeline_by_schedule,
            ]
          },
          'update-gems-cache-for-docker-jobs' => {
            stage: 'prepare',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_cache_update_pipeline_by_schedule,
              :mirror_cache_update_pipeline_by_schedule,
            ]
          },
          'update-trigger-package-cache' => {
            stage: 'prepare',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_cache_update_pipeline_by_schedule,
              :mirror_ee_branch_pipeline_by_trigger_with_cache_update,
            ]
          },
          'dependency_scanning' => {
            stage: 'other',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_dependency_scanning_pipeline_by_schedule,
            ]
          },
          'dependency_update' => {
            stage: 'other',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_deps_pipeline_by_schedule,
            ]
          },
          'dependencies_io_check' => {
            stage: 'other',
            script: ['echo "Hello World"'],
            pipeline_types: [
              :canonical_deps_branch_pipeline,
            ]
          },
        }
      end

      def knapsack_jobs
        {}.tap do |result|
          testable_distros.each do |os, details|
            result["#{os}-knapsack"] = {
              stage: 'prepare',
              script: ['echo "Hello World"'],
              needs: ['rubocop'],
              pipeline_types: [
                :canonical_ce_branch_pipeline,
                :canonical_ee_branch_pipeline,
                :fork_ce_branch_pipeline,
                :fork_ee_branch_pipeline,
              ]
            }
          end
        end
      end

      def spec_jobs
        {}.tap do |result|
          testable_distros.each do |os, details|
            result["#{os}-specs"] = {
              stage: 'test',
              script: ['echo "Hello World"'],
              needs: ["#{os}-knapsack"],
              parallel: 6,
              pipeline_types: [
                :canonical_ce_branch_pipeline,
                :canonical_ee_branch_pipeline,
                :fork_ce_branch_pipeline,
                :fork_ee_branch_pipeline,
              ]
            }
          end
        end
      end
    end
  end
end
