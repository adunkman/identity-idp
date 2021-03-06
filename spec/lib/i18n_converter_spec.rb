require 'spec_helper'
require 'i18n_converter'

RSpec.describe I18nConverter do
  let(:translation_yml) do
    <<~YAML
      ---
      en:
        test:
          key: Some string
        other_test:
          other_key: Other key
          some_key: Some key
    YAML
  end

  let(:translation_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <hash>
        <en>
          <test>
            <key>Some string</key>
          </test>
          <other-test>
            <other-key>Other key</other-key>
            <some-key>Some key</some-key>
          </other-test>
        </en>
      </hash>
    XML
  end

  let(:markdown_md) do
    <<~MD
      ---
      title: Title
      description: Description
      ---
      Some **fancy** markdown
    MD
  end

  let(:markdown_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <hash>
        <front-matter>
          <title>Title</title>
          <description>Description</description>
        </front-matter>
        <content>Some **fancy** markdown
      </content>
      </hash>
    XML
  end

  subject(:converter) { I18nConverter.new(stdin: stdin, stdout: stdout) }

  describe '.yml_to_xml' do
    let(:stdout) { StringIO.new }
    let(:stdin) { StringIO.new(translation_yml) }

    context 'with a TTY on STDIN' do
      let(:stdin) { instance_double('IO', tty?: true) }

      it 'prints an error and exits' do
        expect(converter).to receive(:exit).with(1)

        converter.yml_to_xml

        expect(stdout.string.chomp).to eq("Usage: cat en.yml | #{$PROGRAM_NAME} > output.xml")
      end
    end

    it 'outputs XML' do
      converter.yml_to_xml

      expect(stdout.string).to eq(translation_xml)
    end
  end

  describe '.xml_to_yml' do
    let(:stdout) { StringIO.new }
    let(:stdin) { StringIO.new(translation_xml) }

    context 'with a TTY on STDIN' do
      let(:stdin) { instance_double('IO', tty?: true) }

      it 'prints an error and exits' do
        expect(converter).to receive(:exit).with(1)

        converter.xml_to_yml

        expect(stdout.string.chomp).to eq("Usage: cat en.xml | #{$PROGRAM_NAME} > output.yml")
      end
    end

    it 'outputs YML' do
      converter.xml_to_yml

      expect(stdout.string).to eq(translation_yml)
    end
  end

  describe '.md_to_xml' do
    let(:stdout) { StringIO.new }
    let(:stdin) { StringIO.new(markdown_md) }

    context 'with a TTY on STDIN' do
      let(:stdin) { instance_double('IO', tty?: true) }

      it 'prints an error and exits' do
        expect(converter).to receive(:exit).with(1)

        converter.md_to_xml

        expect(stdout.string.chomp).to eq("Usage: cat en.md | #{$PROGRAM_NAME} > output.xml")
      end
    end

    it 'outputs XML' do
      converter.md_to_xml

      expect(stdout.string).to eq(markdown_xml)
    end
  end

  describe '.xml_to_md' do
    let(:stdout) { StringIO.new }
    let(:stdin) { StringIO.new(markdown_xml) }

    context 'with a TTY on STDIN' do
      let(:stdin) { instance_double('IO', tty?: true) }

      it 'prints an error and exits' do
        expect(converter).to receive(:exit).with(1)

        converter.xml_to_md

        expect(stdout.string.chomp).to eq("Usage: cat en.xml | #{$PROGRAM_NAME} > output.md")
      end
    end

    it 'outputs XML' do
      converter.xml_to_md

      expect(stdout.string).to eq(markdown_md)
    end
  end
end
