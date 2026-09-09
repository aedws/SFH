import unittest
from gdscript_dependencies import reference_paths, named_parent, find_cycle


class ReferencesTest(unittest.TestCase):
    paths = {"Foo": "res://game/features/foo/foo.gd", "Bar": "res://game/features/bar/bar.gd"}

    def test_named_inheritance_and_static_api(self):
        self.assertEqual(reference_paths("class_name Foo\nextends Bar\nvar x: Bar = Bar.new()", self.paths), {self.paths["Bar"]})
        self.assertEqual(named_parent("extends Bar # parent", self.paths), self.paths["Bar"])

    def test_comments_and_strings_are_not_types(self):
        self.assertEqual(reference_paths('''# Bar res://game/features/bar/no.gd
var text = "Bar"
var notes = """Bar
extends Bar
"""
var text2 = 'Foo'
var Fooish = 1''', self.paths), set())

    def test_resource_paths_and_hash_inside_string(self):
        self.assertEqual(reference_paths('var s = "# Bar"; var x = load("res://game/features/foo/foo.tres") # Bar', self.paths), {"res://game/features/foo/foo.tres"})

    def test_reorder_and_future_module(self):
        updated = dict(self.paths, Future="res://game/features/future/new.gd")
        for source in ["Foo.call()\nvar a: Future", "var a: Future\nFoo.call()"]:
            self.assertEqual(reference_paths(source, updated), {self.paths["Foo"], updated["Future"]})

    def test_path_and_type_deduplicate(self):
        self.assertEqual(reference_paths('Bar.new()\nload("res://game/features/bar/bar.gd")', self.paths), {self.paths["Bar"]})

    def test_engine_parent_not_project(self):
        self.assertEqual(named_parent("extends Node", self.paths), "")

    def test_future_named_class_cycle_is_rejected(self):
        sources = {"Foo": "class_name Foo\nextends Bar", "Bar": "class_name Bar\nFoo.new()"}
        by_path = {path: name for name, path in self.paths.items()}
        graph = {name: {by_path[path] for path in reference_paths(source, self.paths)} for name, source in sources.items()}
        self.assertTrue(find_cycle(graph))
        graph["Bar"].clear()
        self.assertEqual(find_cycle(graph), [])


if __name__ == "__main__":
    unittest.main()
