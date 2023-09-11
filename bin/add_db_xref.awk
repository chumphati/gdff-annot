/organism/ {
    organism_found = 1
    print
    print "                     /db_xref=\"taxon:" taxon "\""
    next
}

/organism/ && organism_found {
    print
    next
}

/mol_type/ && !organism_found {
    print
    print "                     /db_xref=\"taxon:" taxon "\""
    next
}

{
    print
}
