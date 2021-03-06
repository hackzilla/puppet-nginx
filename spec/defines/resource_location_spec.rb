require 'spec_helper'

describe 'nginx::resource::location' do
  let :title do
    'rspec-test'
  end
  let :facts do
    {
      :osfamily        => 'Debian',
      :operatingsystem => 'debian',
      :kernel          => 'Linux',
    }
  end
  let :pre_condition do
    [
      'include ::nginx::params',
      'include ::nginx::config',
    ]
  end

  describe 'os-independent items' do

    describe 'basic assumptions' do
      let :params do {
        :www_root => "/var/www/rspec",
        :vhost    => 'vhost1',
      } end

      it { should include_class("nginx::params") }
      it { should include_class("nginx::config") }
      it { should contain_file("/tmp/nginx.d/vhost1-500-rspec-test").with_content(/location rspec-test/) }
      it { should_not contain_file('/etc/nginx/fastcgi_params') }
      it { should_not contain_file("/tmp/nginx.d/vhost1-800-rspec-test-ssl") }
      it { should_not contain_file("/etc/nginx/rspec-test_htpasswd") }
    end

    describe "vhost_location_proxy template content" do
      [
        {
          :title => 'should set the location',
          :attr  => 'location',
          :value => 'my_location',
          :match => '  location my_location {',
        },
        {
          :title => 'should contain ordered prepended directives',
          :attr  => 'location_cfg_prepend',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow         test value 3;',
            '    test1         test value 1;',
            '    test2         test value 2;',
          ],
        },
        {
          :title => 'should set proxy_cache',
          :attr  => 'proxy_cache',
          :value => 'value',
          :match => '    proxy_cache         value;',
        },
        {
          :title    => 'should not set proxy_cache',
          :attr     => 'proxy_cache',
          :value    => false,
          :notmatch => /proxy_cache/
        },
        {
          :title => 'should set proxy_pass',
          :attr  => 'proxy',
          :value => 'value',
          :match => '    proxy_pass          value;',
        },
        {
          :title => 'should set proxy_read_timeout',
          :attr  => 'proxy_read_timeout',
          :value => 'value',
          :match => '    proxy_read_timeout  value;',
        },
        {
          :title => 'should contain ordered appended directives',
          :attr  => 'location_cfg_append',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow test value 3;',
            '    test1 test value 1;',
            '    test2 test value 2;',
          ],
        },
      ].each do |param|
        context "when #{param[:attr]} is #{param[:value]}" do
          let :default_params do { :location => 'location', :proxy => 'proxy_value', :vhost => 'vhost1' } end
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

          it { should contain_file("/tmp/nginx.d/vhost1-500-#{params[:location]}") }
          it param[:title] do
            verify_contents(subject, "/tmp/nginx.d/vhost1-500-#{params[:location]}", Array(param[:match]))
            lines = subject.resource('file', "/tmp/nginx.d/vhost1-500-#{params[:location]}").send(:parameters)[:content].split("\n")
            (Array(param[:notmatch]).collect { |x| lines.grep x }.flatten).should be_empty
          end
        end
      end

      context "when proxy_cache_valid is 10m" do
        let :params do {
          :location => 'location',
          :proxy => 'proxy_value',
          :vhost => 'vhost1',
          :proxy_cache => true,
          :proxy_cache_valid => '10m',
        } end

        it { should contain_file("/tmp/nginx.d/vhost1-500-location").with_content(/proxy_cache_valid   10m;/) }
      end
    end

    describe "vhost_location_alias template content" do
      [
        {
          :title => 'should set the location',
          :attr  => 'location',
          :value => 'my_location',
          :match => '  location my_location {',
        },
        {
          :title => 'should contain ordered prepended directives',
          :attr  => 'location_cfg_prepend',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow test value 3;',
            '    test1 test value 1;',
            '    test2 test value 2;',
          ],
        },
        {
          :title => 'should set alias',
          :attr  => 'location_alias',
          :value => 'value',
          :match => '    alias      value;',
        },
        {
          :title => 'should contain ordered appended directives',
          :attr  => 'location_cfg_append',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow test value 3;',
            '    test1 test value 1;',
            '    test2 test value 2;',
          ],
        },
      ].each do |param|
        context "when #{param[:attr]} is #{param[:value]}" do
          let :default_params do { :location => 'location', :location_alias => 'location_alias_value', :vhost => 'vhost1' } end
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

          it { should contain_file("/tmp/nginx.d/vhost1-500-#{params[:location]}") }
          it param[:title] do
            verify_contents(subject, "/tmp/nginx.d/vhost1-500-#{params[:location]}", Array(param[:match]))
            lines = subject.resource('file', "/tmp/nginx.d/vhost1-500-#{params[:location]}").send(:parameters)[:content].split("\n")
            (Array(param[:notmatch]).collect { |x| lines.grep x }.flatten).should be_empty
          end
        end
      end
    end

    describe "vhost_location_stub_status template content" do
      [
        {
          :title => 'should set the location',
          :attr  => 'location',
          :value => 'my_location',
          :match => '  location my_location {',
        },
        {
          :title => 'should contain ordered prepended directives',
          :attr  => 'location_cfg_prepend',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow  test value 3;',
            '    test1  test value 1;',
            '    test2  test value 2;',
          ],
        },
        {
          :title => 'should contain ordered appended directives',
          :attr  => 'location_cfg_append',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow  test value 3;',
            '    test1  test value 1;',
            '    test2  test value 2;',
          ],
        },
      ].each do |param|
        context "when #{param[:attr]} is #{param[:value]}" do
          let :default_params do { :location => 'location', :stub_status => true, :vhost => 'vhost1' } end
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

          it { should contain_file("/tmp/nginx.d/vhost1-500-#{params[:location]}").with_content(/stub_status on;/) }
          it param[:title] do
            verify_contents(subject, "/tmp/nginx.d/vhost1-500-#{params[:location]}", Array(param[:match]))
            lines = subject.resource('file', "/tmp/nginx.d/vhost1-500-#{params[:location]}").send(:parameters)[:content].split("\n")
            (Array(param[:notmatch]).collect { |x| lines.grep x }.flatten).should be_empty
          end
        end
      end
    end

    describe "vhost_location_fastcgi template content" do
      [
        {
          :title => 'should set the location',
          :attr  => 'location',
          :value => 'my_location',
          :match => '  location my_location {',
        },
        {
          :title => 'should contain ordered prepended directives',
          :attr  => 'location_cfg_prepend',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow         test value 3;',
            '    test1         test value 1;',
            '    test2         test value 2;',
          ],
        },
        {
          :title => 'should set www_root',
          :attr  => 'www_root',
          :value => '/',
          :match => '    root  /;'
        },
        {
          :title => 'should set fastcgi_split_path',
          :attr  => 'fastcgi_split_path',
          :value => 'value',
          :match => '    fastcgi_split_path_info value;'
        },
        {
          :title    => 'should not set fastcgi_split_path',
          :attr     => 'fastcgi_split_path',
          :value    => false,
          :notmatch => /fastcgi_split_path_info/
        },
        {
          :title => 'should set try_file(s)',
          :attr  => 'try_files',
          :value => ['name1','name2'],
          :match => '    try_files name1 name2;',
        },
        {
          :title => 'should set fastcgi_params',
          :attr  => 'fastcgi_params',
          :value => 'value',
          :match => '    include value;'
        },
        {
          :title => 'should set fastcgi_pass',
          :attr  => 'fastcgi',
          :value => 'value',
          :match => '    fastcgi_pass value;'
        },
        {
          :title => 'should set fastcgi_param',
          :attr  => 'fastcgi_script',
          :value => 'value',
          :match => '    fastcgi_param SCRIPT_FILENAME value;',
        },
        {
          :title => 'should contain ordered appended directives',
          :attr  => 'location_cfg_append',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow test value 3;',
            '    test1 test value 1;',
            '    test2 test value 2;',
          ],
        },
      ].each do |param|
        context "when #{param[:attr]} is #{param[:value]}" do
          let :default_params do { :location => 'location', :fastcgi => true, :vhost => 'vhost1' } end
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

          it { should contain_file("/tmp/nginx.d/vhost1-500-#{params[:location]}") }
          it param[:title] do
            verify_contents(subject, "/tmp/nginx.d/vhost1-500-#{params[:location]}", Array(param[:match]))
            lines = subject.resource('file', "/tmp/nginx.d/vhost1-500-#{params[:location]}").send(:parameters)[:content].split("\n")
            (Array(param[:notmatch]).collect { |x| lines.grep x }.flatten).should be_empty
          end
        end
      end
    end

    describe "vhost_location_directory template content" do
      [
        {
          :title => 'should set the location',
          :attr  => 'location',
          :value => 'my_location',
          :match => '  location my_location {',
        },
        {
          :title => 'should set the allow directive',
          :attr  => 'location_allow',
          :value => ['rule1','rule2'],
          :match => ['  allow rule1;', '  allow rule2;'],
        },
        {
          :title => 'should set the deny directive',
          :attr  => 'location_deny',
          :value => ['rule1','rule2'],
          :match => ['  deny rule1;', '  deny rule2;'],
        },
        {
          :title => 'should contain ordered prepended directives',
          :attr  => 'location_cfg_prepend',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow test value 3;',
            '    test1 test value 1;',
            '    test2 test value 2;',
          ],
        },
        {
          :title => 'should set www_root',
          :attr  => 'www_root',
          :value => '/',
          :match => '    root  /;'
        },
        {
          :title => 'should set try_file(s)',
          :attr  => 'try_files',
          :value => ['name1','name2'],
          :match => '    try_files name1 name2;',
        },
        {
          :title => 'should set index_file(s)',
          :attr  => 'index_files',
          :value => ['name1','name2'],
          :match => '    index  name1 name2;',
        },
        {
          :title => 'should set auth_basic',
          :attr  => 'auth_basic',
          :value => 'value',
          :match => '    auth_basic           "value";',
        },
        {
          :title => 'should set auth_basic_user_file',
          :attr  => 'auth_basic_user_file',
          :value => 'value',
          :match => '    auth_basic_user_file value;',
        },
        {
          :title => 'should contain ordered appended directives',
          :attr  => 'location_cfg_append',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow test value 3;',
            '    test1 test value 1;',
            '    test2 test value 2;',
          ],
        },
      ].each do |param|
        context "when #{param[:attr]} is #{param[:value]}" do
          let :default_params do { :location => 'location', :www_root => '/var/www/root', :vhost => 'vhost1' } end
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

          it { should contain_file("/tmp/nginx.d/vhost1-500-#{params[:location]}") }
          it param[:title] do
            verify_contents(subject, "/tmp/nginx.d/vhost1-500-#{params[:location]}", Array(param[:match]))
            lines = subject.resource('file', "/tmp/nginx.d/vhost1-500-#{params[:location]}").send(:parameters)[:content].split("\n")
            (Array(param[:notmatch]).collect { |x| lines.grep x }.flatten).should be_empty
          end
        end
      end
    end

    describe "vhost_location_empty template content" do
      [
        {
          :title => 'should set the location',
          :attr  => 'location',
          :value => 'my_location',
          :match => '  location my_location {',
        },
        {
          :title => 'should contain ordered config directives',
          :attr  => 'location_custom_cfg',
          :value => { 'test1' => 'test value 1', 'test2' => 'test value 2', 'allow' => 'test value 3' },
          :match => [
            '    allow test value 3;',
            '    test1 test value 1;',
            '    test2 test value 2;',
          ],
        },
      ].each do |param|
        context "when #{param[:attr]} is #{param[:value]}" do
          let :default_params do { :location => 'location', :location_custom_cfg => {'test1'=>'value1'}, :vhost => 'vhost1' } end
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

          it { should contain_file("/tmp/nginx.d/vhost1-500-#{params[:location]}") }
          it param[:title] do
            verify_contents(subject, "/tmp/nginx.d/vhost1-500-#{params[:location]}", Array(param[:match]))
            lines = subject.resource('file', "/tmp/nginx.d/vhost1-500-#{params[:location]}").send(:parameters)[:content].split("\n")
            (Array(param[:notmatch]).collect { |x| lines.grep x }.flatten).should be_empty
          end
        end
      end
    end

    context 'attribute resources' do
      context 'when fastcgi => true' do
        let :params do { :fastcgi => true, :vhost => 'vhost1' } end

        it { should contain_file('/etc/nginx/fastcgi_params').with_mode('0770') }
      end

      context 'when ssl_only => true' do
        let :params do { :ssl_only => true, :vhost => 'vhost1', :www_root => '/', } end
        it { should_not contain_file("/tmp/nginx.d/vhost1-500-rspec-test") }
      end

      context 'when ssl_only => false' do
        let :params do { :ssl_only => false, :vhost => 'vhost1', :www_root => '/', } end

        it { should contain_file("/tmp/nginx.d/vhost1-500-rspec-test") }
      end

      context 'when ssl => true' do
        let :params do { :ssl => true, :vhost => 'vhost1', :www_root => '/', } end

        it { should contain_file("/tmp/nginx.d/vhost1-800-rspec-test-ssl") }
      end

      context 'when ssl => false' do
        let :params do { :ssl => false, :vhost => 'vhost1', :www_root => '/', } end

        it { should_not contain_file("/tmp/nginx.d/vhost1-800-rspec-test-ssl") }
      end

      context 'when auth_basic_user_file => true' do
        let :params do { :auth_basic_user_file => true, :vhost => 'vhost1', :www_root => '/', } end

        it { should contain_file("/etc/nginx/rspec-test_htpasswd") }
      end

      context 'when ensure => absent' do
        let :params do {
          :www_root             => true,
          :vhost                => 'vhost1',
          :ensure               => 'absent',
          :ssl                  => true,
          :auth_basic_user_file => true,
        } end

        it { should contain_file("/tmp/nginx.d/vhost1-500-rspec-test").with_ensure('absent') }
        it { should contain_file("/tmp/nginx.d/vhost1-800-rspec-test-ssl").with_ensure('absent') }
        it { should contain_file("/etc/nginx/rspec-test_htpasswd").with_ensure('absent') }
      end

      context "vhost missing" do
        let :params do {
          :www_root => '/',
        } end

        it { expect { should contain_class('nginx::resource::location') }.to raise_error(Puppet::Error, /Cannot create a location reference without attaching to a virtual host/) }
      end

      context "location type missing" do
        let :params do {
          :vhost => 'vhost1',
        } end

        it { expect { should contain_class('nginx::resource::location') }.to raise_error(Puppet::Error, /Cannot create a location reference without a www_root, proxy, location_alias, fastcgi, stub_status, or location_custom_cfg defined/) }
      end

      context "www_root and proxy are set" do
        let :params do {
          :vhost    => 'vhost1',
          :www_root => '/',
          :proxy    => true,
        } end

        it { expect { should contain_class('nginx::resource::location') }.to raise_error(Puppet::Error, /Cannot define both directory and proxy in a virtual host/) }
      end
    end
  end
end
