# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::QuickActionPipeline, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  it 'does not detect a quick action' do
    markdown = <<~MD.strip
      <!-- HTML comment -->
      A paragraph

      > a blockquote
    MD
    result = described_class.call(markdown, project: nil)

    expect(result[:quick_action_paragraphs]).to be_empty
  end

  it 'does detect a quick action' do
    markdown = <<~MD.strip
      <!-- HTML comment -->
      /quick

      > a blockquote
    MD
    result = described_class.call(markdown, project: nil)

    expect(result[:quick_action_paragraphs]).to match_array [{ start_line: 1, end_line: 1 }]
  end

  it 'does detect a multiple quick actions but not in a multi-line blockquote' do
    markdown = <<~MD.strip
      Lorem ipsum
      /quick
      /action

      >>>
      /quick
      >>>

      /action
    MD
    result = described_class.call(markdown, project: nil)

    expect(result[:quick_action_paragraphs])
      .to match_array [{ start_line: 0, end_line: 2 }, { start_line: 8, end_line: 8 }]
  end

  it 'does not a quick action in a code block' do
    markdown = <<~MD.strip
      ```
      Lorem ipsum
      /quick
      /action
      ```
    MD
    result = described_class.call(markdown, project: nil)

    expect(result[:quick_action_paragraphs]).to be_empty
  end
end
