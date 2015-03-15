import QtQuick 2.0
import QtTest 1.0
import Protobuf 1.0 as Protobuf
import 'ProtobufQmlTest.pb.js' as Test1
import 'ProtobufQmlTest2.pb.js' as Test2

Item {
  Protobuf.MemoryBuffer {
    id: buffer
  }

  TestCase {
    name: 'SerializeTest'

    function init() {
      buffer.clear();
      buffer.size = 1000;
    }

    function test_serialize_undefined() {
      var called = {};
      var msg1 = new Test1.Msg1({field1: 42});
      msg1.serializeTo(undefined, function() {
        fail();
      }, function(err) {
        called.value = true;
      });
      tryCompare(called, 'value', true, 100);
    }

    function test_serialize_size0() {
      var called = {};
      buffer.size = 0;
      var msg1 = new Test1.Msg1({field1: 42});
      msg1.serializeTo(buffer.output, function() {
        fail();
      }, function(err) {
        called.value = true;
      });
      tryCompare(called, 'value', true, 100);
    }
  }
}