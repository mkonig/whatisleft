[default]
test:
    bats -T test/

test-fast:
    bats --filter-tags "!e2e" -T test/

test-e2e:
    bats --filter-tags "e2e" -T test/
