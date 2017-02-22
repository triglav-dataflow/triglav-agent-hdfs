# this is a generated file, to avoid over-writing it just delete this comment
begin
  require 'jar_dependencies'
rescue LoadError
  require 'org/apache/httpcomponents/httpcore/4.2.4/httpcore-4.2.4.jar'
  require 'log4j/log4j/1.2.17/log4j-1.2.17.jar'
  require 'com/google/protobuf/protobuf-java/2.5.0/protobuf-java-2.5.0.jar'
  require 'org/apache/commons/commons-compress/1.4.1/commons-compress-1.4.1.jar'
  require 'org/apache/directory/server/apacheds-kerberos-codec/2.0.0-M15/apacheds-kerberos-codec-2.0.0-M15.jar'
  require 'org/apache/curator/curator-recipes/2.6.0/curator-recipes-2.6.0.jar'
  require 'org/apache/hadoop/hadoop-hdfs/2.6.5/hadoop-hdfs-2.6.5.jar'
  require 'org/apache/commons/commons-math3/3.1.1/commons-math3-3.1.1.jar'
  require 'org/apache/hadoop/hadoop-auth/2.6.5/hadoop-auth-2.6.5.jar'
  require 'org/apache/hadoop/hadoop-mapreduce-client-shuffle/2.6.5/hadoop-mapreduce-client-shuffle-2.6.5.jar'
  require 'org/fusesource/leveldbjni/leveldbjni-all/1.8/leveldbjni-all-1.8.jar'
  require 'org/mortbay/jetty/jetty-util/6.1.26/jetty-util-6.1.26.jar'
  require 'org/slf4j/slf4j-log4j12/1.7.5/slf4j-log4j12-1.7.5.jar'
  require 'commons-io/commons-io/2.4/commons-io-2.4.jar'
  require 'org/apache/hadoop/hadoop-mapreduce-client-core/2.6.5/hadoop-mapreduce-client-core-2.6.5.jar'
  require 'org/codehaus/jackson/jackson-mapper-asl/1.9.13/jackson-mapper-asl-1.9.13.jar'
  require 'org/slf4j/slf4j-api/1.7.5/slf4j-api-1.7.5.jar'
  require 'com/sun/jersey/jersey-core/1.9/jersey-core-1.9.jar'
  require 'org/codehaus/jackson/jackson-jaxrs/1.9.13/jackson-jaxrs-1.9.13.jar'
  require 'xml-apis/xml-apis/1.3.04/xml-apis-1.3.04.jar'
  require 'xmlenc/xmlenc/0.52/xmlenc-0.52.jar'
  require 'com/thoughtworks/paranamer/paranamer/2.3/paranamer-2.3.jar'
  require 'org/codehaus/jackson/jackson-core-asl/1.9.13/jackson-core-asl-1.9.13.jar'
  require 'org/apache/directory/api/api-util/1.0.0-M20/api-util-1.0.0-M20.jar'
  require 'com/google/code/gson/gson/2.2.4/gson-2.2.4.jar'
  require 'org/apache/directory/api/api-asn1-api/1.0.0-M20/api-asn1-api-1.0.0-M20.jar'
  require 'com/sun/jersey/jersey-client/1.9/jersey-client-1.9.jar'
  require 'org/apache/curator/curator-client/2.6.0/curator-client-2.6.0.jar'
  require 'org/apache/hadoop/hadoop-mapreduce-client-common/2.6.5/hadoop-mapreduce-client-common-2.6.5.jar'
  require 'commons-net/commons-net/3.1/commons-net-3.1.jar'
  require 'commons-configuration/commons-configuration/1.6/commons-configuration-1.6.jar'
  require 'com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar'
  require 'commons-digester/commons-digester/1.8/commons-digester-1.8.jar'
  require 'org/apache/hadoop/hadoop-mapreduce-client-jobclient/2.6.5/hadoop-mapreduce-client-jobclient-2.6.5.jar'
  require 'org/apache/directory/server/apacheds-i18n/2.0.0-M15/apacheds-i18n-2.0.0-M15.jar'
  require 'commons-beanutils/commons-beanutils/1.7.0/commons-beanutils-1.7.0.jar'
  require 'javax/xml/bind/jaxb-api/2.2.2/jaxb-api-2.2.2.jar'
  require 'commons-lang/commons-lang/2.6/commons-lang-2.6.jar'
  require 'org/htrace/htrace-core/3.0.4/htrace-core-3.0.4.jar'
  require 'javax/activation/activation/1.1/activation-1.1.jar'
  require 'org/apache/zookeeper/zookeeper/3.4.6/zookeeper-3.4.6.jar'
  require 'org/tukaani/xz/1.0/xz-1.0.jar'
  require 'org/apache/hadoop/hadoop-client/2.6.5/hadoop-client-2.6.5.jar'
  require 'commons-cli/commons-cli/1.2/commons-cli-1.2.jar'
  require 'xerces/xercesImpl/2.9.1/xercesImpl-2.9.1.jar'
  require 'org/apache/httpcomponents/httpclient/4.2.5/httpclient-4.2.5.jar'
  require 'commons-codec/commons-codec/1.4/commons-codec-1.4.jar'
  require 'org/apache/hadoop/hadoop-yarn-api/2.6.5/hadoop-yarn-api-2.6.5.jar'
  require 'org/apache/hadoop/hadoop-common/2.6.5/hadoop-common-2.6.5.jar'
  require 'commons-beanutils/commons-beanutils-core/1.8.0/commons-beanutils-core-1.8.0.jar'
  require 'commons-collections/commons-collections/3.2.2/commons-collections-3.2.2.jar'
  require 'javax/xml/stream/stax-api/1.0-2/stax-api-1.0-2.jar'
  require 'org/apache/hadoop/hadoop-yarn-client/2.6.5/hadoop-yarn-client-2.6.5.jar'
  require 'org/codehaus/jackson/jackson-xc/1.9.13/jackson-xc-1.9.13.jar'
  require 'commons-logging/commons-logging/1.1.3/commons-logging-1.1.3.jar'
  require 'org/apache/hadoop/hadoop-mapreduce-client-app/2.6.5/hadoop-mapreduce-client-app-2.6.5.jar'
  require 'org/apache/hadoop/hadoop-yarn-server-common/2.6.5/hadoop-yarn-server-common-2.6.5.jar'
  require 'javax/servlet/servlet-api/2.5/servlet-api-2.5.jar'
  require 'com/google/guava/guava/11.0.2/guava-11.0.2.jar'
  require 'org/apache/hadoop/hadoop-yarn-common/2.6.5/hadoop-yarn-common-2.6.5.jar'
  require 'org/xerial/snappy/snappy-java/1.0.4.1/snappy-java-1.0.4.1.jar'
  require 'org/apache/curator/curator-framework/2.6.0/curator-framework-2.6.0.jar'
  require 'org/apache/hadoop/hadoop-annotations/2.6.5/hadoop-annotations-2.6.5.jar'
  require 'org/apache/avro/avro/1.7.4/avro-1.7.4.jar'
  require 'io/netty/netty/3.6.2.Final/netty-3.6.2.Final.jar'
  require 'commons-httpclient/commons-httpclient/3.1/commons-httpclient-3.1.jar'
end

if defined? Jars
  require_jar( 'org.apache.httpcomponents', 'httpcore', '4.2.4' )
  require_jar( 'log4j', 'log4j', '1.2.17' )
  require_jar( 'com.google.protobuf', 'protobuf-java', '2.5.0' )
  require_jar( 'org.apache.commons', 'commons-compress', '1.4.1' )
  require_jar( 'org.apache.directory.server', 'apacheds-kerberos-codec', '2.0.0-M15' )
  require_jar( 'org.apache.curator', 'curator-recipes', '2.6.0' )
  require_jar( 'org.apache.hadoop', 'hadoop-hdfs', '2.6.5' )
  require_jar( 'org.apache.commons', 'commons-math3', '3.1.1' )
  require_jar( 'org.apache.hadoop', 'hadoop-auth', '2.6.5' )
  require_jar( 'org.apache.hadoop', 'hadoop-mapreduce-client-shuffle', '2.6.5' )
  require_jar( 'org.fusesource.leveldbjni', 'leveldbjni-all', '1.8' )
  require_jar( 'org.mortbay.jetty', 'jetty-util', '6.1.26' )
  require_jar( 'org.slf4j', 'slf4j-log4j12', '1.7.5' )
  require_jar( 'commons-io', 'commons-io', '2.4' )
  require_jar( 'org.apache.hadoop', 'hadoop-mapreduce-client-core', '2.6.5' )
  require_jar( 'org.codehaus.jackson', 'jackson-mapper-asl', '1.9.13' )
  require_jar( 'org.slf4j', 'slf4j-api', '1.7.5' )
  require_jar( 'com.sun.jersey', 'jersey-core', '1.9' )
  require_jar( 'org.codehaus.jackson', 'jackson-jaxrs', '1.9.13' )
  require_jar( 'xml-apis', 'xml-apis', '1.3.04' )
  require_jar( 'xmlenc', 'xmlenc', '0.52' )
  require_jar( 'com.thoughtworks.paranamer', 'paranamer', '2.3' )
  require_jar( 'org.codehaus.jackson', 'jackson-core-asl', '1.9.13' )
  require_jar( 'org.apache.directory.api', 'api-util', '1.0.0-M20' )
  require_jar( 'com.google.code.gson', 'gson', '2.2.4' )
  require_jar( 'org.apache.directory.api', 'api-asn1-api', '1.0.0-M20' )
  require_jar( 'com.sun.jersey', 'jersey-client', '1.9' )
  require_jar( 'org.apache.curator', 'curator-client', '2.6.0' )
  require_jar( 'org.apache.hadoop', 'hadoop-mapreduce-client-common', '2.6.5' )
  require_jar( 'commons-net', 'commons-net', '3.1' )
  require_jar( 'commons-configuration', 'commons-configuration', '1.6' )
  require_jar( 'com.google.code.findbugs', 'jsr305', '1.3.9' )
  require_jar( 'commons-digester', 'commons-digester', '1.8' )
  require_jar( 'org.apache.hadoop', 'hadoop-mapreduce-client-jobclient', '2.6.5' )
  require_jar( 'org.apache.directory.server', 'apacheds-i18n', '2.0.0-M15' )
  require_jar( 'commons-beanutils', 'commons-beanutils', '1.7.0' )
  require_jar( 'javax.xml.bind', 'jaxb-api', '2.2.2' )
  require_jar( 'commons-lang', 'commons-lang', '2.6' )
  require_jar( 'org.htrace', 'htrace-core', '3.0.4' )
  require_jar( 'javax.activation', 'activation', '1.1' )
  require_jar( 'org.apache.zookeeper', 'zookeeper', '3.4.6' )
  require_jar( 'org.tukaani', 'xz', '1.0' )
  require_jar( 'org.apache.hadoop', 'hadoop-client', '2.6.5' )
  require_jar( 'commons-cli', 'commons-cli', '1.2' )
  require_jar( 'xerces', 'xercesImpl', '2.9.1' )
  require_jar( 'org.apache.httpcomponents', 'httpclient', '4.2.5' )
  require_jar( 'commons-codec', 'commons-codec', '1.4' )
  require_jar( 'org.apache.hadoop', 'hadoop-yarn-api', '2.6.5' )
  require_jar( 'org.apache.hadoop', 'hadoop-common', '2.6.5' )
  require_jar( 'commons-beanutils', 'commons-beanutils-core', '1.8.0' )
  require_jar( 'commons-collections', 'commons-collections', '3.2.2' )
  require_jar( 'javax.xml.stream', 'stax-api', '1.0-2' )
  require_jar( 'org.apache.hadoop', 'hadoop-yarn-client', '2.6.5' )
  require_jar( 'org.codehaus.jackson', 'jackson-xc', '1.9.13' )
  require_jar( 'commons-logging', 'commons-logging', '1.1.3' )
  require_jar( 'org.apache.hadoop', 'hadoop-mapreduce-client-app', '2.6.5' )
  require_jar( 'org.apache.hadoop', 'hadoop-yarn-server-common', '2.6.5' )
  require_jar( 'javax.servlet', 'servlet-api', '2.5' )
  require_jar( 'com.google.guava', 'guava', '11.0.2' )
  require_jar( 'org.apache.hadoop', 'hadoop-yarn-common', '2.6.5' )
  require_jar( 'org.xerial.snappy', 'snappy-java', '1.0.4.1' )
  require_jar( 'org.apache.curator', 'curator-framework', '2.6.0' )
  require_jar( 'org.apache.hadoop', 'hadoop-annotations', '2.6.5' )
  require_jar( 'org.apache.avro', 'avro', '1.7.4' )
  require_jar( 'io.netty', 'netty', '3.6.2.Final' )
  require_jar( 'commons-httpclient', 'commons-httpclient', '3.1' )
end
