require_relative 'setup'

require 'yaml'
require 'jars/classpath'

module Jars
  def self.prepare( array )
    result = array.collect do |a|
      a.sub( /-native.jar$/, '.jar')
        .sub( /-[^-]+$/, '.jar')
        .sub( /[^\/]+\/([^\/]+)$/, '\1')
        .sub( /.*#{Jars.home}./, '' )
    end
    # omit ruby-maven jars
    result.delete_if { |c| c =~ /ruby-maven/ }
    result.sort.to_yaml
  end
end

describe Jars::Classpath do

  let( :deps ) { File.join( pwd, 'deps.txt' ) }

  let( :pwd ) { File.dirname( File.expand_path( __FILE__ ) ) }

  let( :jars_lock ) { File.join( pwd, 'Jars.lock' ) }

  let( :example_spec ) { File.join( pwd, '..', 'example', 'example.gemspec' ) }

  let( :example_expected ) { ["joda-time/joda-time/2.3/joda-time-2.3.jar", "com/martiansoftware/nailgun-server/0.9.1/nailgun-server-0.9.1.jar", "org/bouncycastle/bcpkix-jdk15on/1.49/bcpkix-jdk15on-1.49.jar", "com/github/jnr/jffi/1.2.7/jffi-1.2.7-native.jar", "org/ow2/asm/asm-analysis/4.0/asm-analysis-4.0.jar", "org/jruby/joni/joni/2.1.2/joni-2.1.2.jar", "com/jcraft/jzlib/1.1.2/jzlib-1.1.2.jar", "com/github/jnr/jnr-enxio/0.4/jnr-enxio-0.4.jar", "com/github/jnr/jnr-netdb/1.1.2/jnr-netdb-1.1.2.jar", "org/bouncycastle/bcprov-jdk15on/1.49/bcprov-jdk15on-1.49.jar", "org/ow2/asm/asm-commons/4.0/asm-commons-4.0.jar", "org/ow2/asm/asm-util/4.0/asm-util-4.0.jar", "org/jruby/yecht/1.0/yecht-1.0.jar", "com/headius/invokebinder/1.2/invokebinder-1.2.jar", "org/ow2/asm/asm-tree/4.0/asm-tree-4.0.jar", "org/jruby/jruby-core/1.7.15/jruby-core-1.7.15.jar", "org/jruby/extras/bytelist/1.0.11/bytelist-1.0.11.jar", "org/jruby/jcodings/jcodings/1.0.10/jcodings-1.0.10.jar", "com/github/jnr/jnr-x86asm/1.0.2/jnr-x86asm-1.0.2.jar", "com/github/jnr/jffi/1.2.7/jffi-1.2.7.jar", "org/yaml/snakeyaml/1.13/snakeyaml-1.13.jar", "com/github/jnr/jnr-posix/3.0.6/jnr-posix-3.0.6.jar", "com/github/jnr/jnr-constants/0.8.5/jnr-constants-0.8.5.jar", "com/headius/options/1.2/options-1.2.jar", "com/github/jnr/jnr-unixsocket/0.3/jnr-unixsocket-0.3.jar", "com/github/jnr/jnr-ffi/1.0.10/jnr-ffi-1.0.10.jar", "org/ow2/asm/asm/4.0/asm-4.0.jar"] }

  let( :expected_string ) do
    example_expected.collect { |c| "#{Jars.home}/#{c}" }
  end

  let( :lock_expected ) { ["org/apache/maven/maven-repository-metadata/3.1.0/maven-repository-metadata-3.1.0.jar", "com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar", "org/apache/httpcomponents/httpclient/4.2.3/httpclient-4.2.3.jar", "org/sonatype/sisu/sisu-guice/3.1.0/sisu-guice-no_aop-3.1.0.jar", "${java.home}/../lib/tools.jar", "org/sonatype/plexus/plexus-cipher/1.4/plexus-cipher-1.4.jar"]
 }

  let( :lock_expected_runtime ) { ["org/apache/maven/maven-repository-metadata/3.1.0/maven-repository-metadata-3.1.0.jar", "org/sonatype/sisu/sisu-guice/3.1.0/sisu-guice-no_aop-3.1.0.jar", "${java.home}/../lib/tools.jar", "org/sonatype/plexus/plexus-cipher/1.4/plexus-cipher-1.4.jar"] }

  let( :lock_expected_test ) { ["org/apache/maven/maven-repository-metadata/3.1.0/maven-repository-metadata-3.1.0.jar", "com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar", "org/apache/httpcomponents/httpclient/4.2.3/httpclient-4.2.3.jar", "org/sonatype/sisu/sisu-guice/3.1.0/sisu-guice-no_aop-3.1.0.jar", "${java.home}/../lib/tools.jar", "org/slf4j/slf4j-api/1.6.2/slf4j-api-1.6.2.jar"] }

  let( :bouncycastle ) { [ "#{Jars.home}/org/bouncycastle/bcpkix-jdk15on/1.49/bcpkix-jdk15on-1.49.jar", "#{Jars.home}/org/bouncycastle/bcprov-jdk15on/1.49/bcprov-jdk15on-1.49.jar" ] }

  subject { Jars::Classpath.new( example_spec ) }

  after do
    ENV_JAVA[ 'jars.quiet' ] = nil
    Jars.reset
  end

  it 'resolves classpath from gemspec' do
    ENV_JAVA[ 'jars.quiet' ] = 'true'
    Jars.prepare( subject.classpath ).must_equal Jars.prepare( example_expected )

    Jars.prepare( subject.classpath( :compile ) ).must_equal Jars.prepare( example_expected )

    Jars.prepare( subject.classpath( :test ) ).must_equal Jars.prepare( example_expected << 'junit/junit/4.1/junit-4.1.jar' )

    Jars.prepare( subject.classpath( :runtime ) ).must_equal Jars.prepare( bouncycastle )
  end

  it 'resolves classpath_string from gemspec' do
      Jars.prepare( subject.classpath_string.split( /#{File::PATH_SEPARATOR}/ ) ).must_equal Jars.prepare( expected_string )

    Jars.prepare( subject.classpath_string( :compile ).split( /#{File::PATH_SEPARATOR}/ ) ).must_equal Jars.prepare( expected_string )

    Jars.prepare( subject.classpath_string( :test ).split( /#{File::PATH_SEPARATOR}/ ) ).must_equal Jars.prepare( expected_string << "junit/junit/4.1/junit-4.1.jar" )

    Jars.prepare( subject.classpath_string( :runtime ).split( /#{File::PATH_SEPARATOR}/ ) ).must_equal Jars.prepare( bouncycastle )
  end

  it 'requires classpath from gemspec' do
    skip( 'jruby-9.0.0.0.pre1 can not require jruby core jars' ) if JRUBY_VERSION == '9.0.0.0.pre1'

    old = $CLASSPATH.to_a
    
    expected = bouncycastle

    subject.require( :runtime )
    Jars.prepare( $CLASSPATH.to_a - old ).must_equal Jars.prepare( expected )

    expected = expected + (expected_string - expected)
    subject.require( :compile )
    Jars.prepare( $CLASSPATH.to_a - old ).must_equal Jars.prepare( expected )

    expected << "junit/junit/4.1/junit-4.1.jar"
    subject.require( :test )
    Jars.prepare( $CLASSPATH.to_a - old ).must_equal Jars.prepare( expected )
  end

  it 'processes Jars.load if exists' do
    def subject.jars_lock( lock = nil )
      @lock = lock if lock
      @lock
    end
    subject.jars_lock( jars_lock )

    Jars.prepare( subject.classpath ).must_equal Jars.prepare( lock_expected )
    Jars.prepare( subject.classpath( :compile ) ).must_equal Jars.prepare( lock_expected )

    Jars.prepare( subject.classpath( :runtime ) ).must_equal Jars.prepare( lock_expected_runtime )

    Jars.prepare( subject.classpath( :test ) ).must_equal Jars.prepare( lock_expected_test )
  end
end
