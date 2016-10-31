def assert_similar_structure(dt1, dt2):
    assert issubclass(dt1.__class__, dt2.__class__) or issubclass(dt2.__class__, dt1.__class__)

    if not isinstance(dt1, (list, dict)):
        return

    assert len(dt1) == len(dt2)

    if isinstance(dt1, list):
        for item in zip(dt1, dt2):
            assert_similar_structure(*item)
    else:
        assert set(dt1.keys()) == set(dt2.keys())
        assert_similar_structure(sorted(dt1.values()), sorted(dt2.values()))
