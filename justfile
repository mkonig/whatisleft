[default]
test:
    bats test/

test-e2e:
    bats --filter-tags "e2e" -T test/
