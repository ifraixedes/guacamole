# -*- encoding : utf-8 -*-

require 'spec_helper'
require 'guacamole/edge_collection'

# /// What do we need?
#
# 2. Each EachCollection needs the following features
#   * Provide access to graph functions provided by Ashikawa::Core (i.e. Neighbors function)

describe Guacamole::EdgeCollection do
  let(:graph)  { double('Graph') }
# /// What do we need?
#
# 2. Each EachCollection needs the following features
#   * Provide access to graph functions provided by Ashikawa::Core (i.e. Neighbors function)

 let(:config) { double('Configuration') }

  before do
    allow(Guacamole).to receive(:configuration).and_return(config)
    allow(config).to receive(:graph).and_return(graph)
    allow(graph).to receive(:add_edge_definition)
  end

  context 'the edge collection module' do
    subject { Guacamole::EdgeCollection }

    context 'with user defined edge collection class' do
      let(:edge_class) { double('EdgeClass', name: 'MyEdge') }
      let(:user_defined_edge_collection) { double('EdgeCollection') }

      before do
        stub_const('MyEdgesCollection', user_defined_edge_collection)
        allow(user_defined_edge_collection).to receive(:add_edge_definition_to_graph)
      end

      it 'should return the edge collection for a given edge class' do
        expect(subject.for(edge_class)).to eq user_defined_edge_collection
      end
    end

    context 'without user defined edge collection class' do
      let(:edge_class) { double('EdgeClass', name: 'AmazingEdge') }
      let(:auto_defined_edge_collection) { double('EdgeCollection') }

      before do
        stub_const('ExampleEdge', double('Edge').as_null_object)
        allow(auto_defined_edge_collection).to receive(:add_edge_definition_to_graph)
      end

      it 'should create an edge collection class' do
        edge_collection = subject.create_edge_collection('ExampleEdgesCollection')

        expect(edge_collection.name).to eq 'ExampleEdgesCollection'
        expect(edge_collection.ancestors).to include Guacamole::EdgeCollection
      end
        
      it 'should return the edge collection for a givene edge class' do
        allow(subject).to receive(:create_edge_collection)
          .with('AmazingEdgesCollection')
          .and_return(auto_defined_edge_collection)

        expect(subject.for(edge_class)).to eq auto_defined_edge_collection
      end
    end
  end

  context 'concrete edge collections' do
    subject do
      class SomeEdgesCollection
        include Guacamole::EdgeCollection
      end
    end

    let(:database) { double('Database') }
    let(:edge_collection_name) { 'some_edges' }
    let(:raw_edge_collection) { double('Ashikawa::Core::EdgeCollection') }
    let(:collection_a) { :a }
    let(:collection_b) { :b }
    let(:edge_class) { double('EdgeClass', name: 'SomeEdge', from: collection_a, to: collection_b)}

    before do
      stub_const('SomeEdge', edge_class)
      allow(graph).to receive(:edge_collection).with(edge_collection_name).and_return(raw_edge_collection)
      allow(subject).to receive(:database).and_return(database)
      allow(graph).to receive(:add_edge_definition)
    end

    after do
      # This stunt is required to have a fresh subject each time and not running into problems
      # with cached mock doubles that will raise errors upon test execution.
      Object.send(:remove_const, subject.name)
    end

    its(:edge_class) { should eq edge_class }
    its(:graph)      { should eq graph }

    it 'should be a specialized Guacamole::Collection' do
      expect(subject).to include Guacamole::Collection 
    end

    it 'should map the #connectino to the underlying edge_connection' do
      allow(subject).to receive(:graph).and_return(graph)
      
      expect(subject.connection).to eq raw_edge_collection
    end

    context 'initialize the edge definition' do
      it 'should add the edge definition as soon as the module is included' do
        just_another_edge_collection = Class.new
        expect(just_another_edge_collection).to receive(:add_edge_definition_to_graph)

        just_another_edge_collection.send(:include, Guacamole::EdgeCollection)
      end
      
      it 'should create the edge definition based on the edge class' do
        expect(graph).to receive(:add_edge_definition).with(edge_collection_name, from: [collection_a], to: [collection_b])

        subject.add_edge_definition_to_graph
      end
    end

    it 'should provide a #neighbors function'
  end
end
