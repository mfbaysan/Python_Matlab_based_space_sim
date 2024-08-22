for dataind = 1:10
    clearvars -except dataind
    setupScene
    setupObject
    simulation
    save(sprintf('gen/test%d',dataind))
end