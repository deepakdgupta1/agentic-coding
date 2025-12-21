"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import { Search, BookOpen, ArrowLeft, Lightbulb, ChevronRight } from "lucide-react";
import { Card } from "@/components/ui/card";
import { getAllTerms, type JargonTerm } from "@/lib/jargon";

/**
 * Group terms by their first letter
 */
function groupByFirstLetter(terms: JargonTerm[]): Map<string, JargonTerm[]> {
  const groups = new Map<string, JargonTerm[]>();

  for (const term of terms) {
    const firstLetter = term.term.charAt(0).toUpperCase();
    const existing = groups.get(firstLetter) || [];
    existing.push(term);
    groups.set(firstLetter, existing);
  }

  // Sort within each group
  for (const [letter, terms] of groups) {
    groups.set(letter, terms.sort((a, b) => a.term.localeCompare(b.term)));
  }

  return groups;
}

/**
 * Get a URL-safe id from a term
 */
function getTermId(term: string): string {
  return term.toLowerCase().replace(/[^a-z0-9]+/g, "-");
}

export default function GlossaryPage() {
  const [searchQuery, setSearchQuery] = useState("");
  const allTerms = useMemo(() => getAllTerms(), []);

  // Filter terms based on search
  const filteredTerms = useMemo(() => {
    if (!searchQuery.trim()) return allTerms;

    const query = searchQuery.toLowerCase();
    return allTerms.filter(
      (term) =>
        term.term.toLowerCase().includes(query) ||
        term.short.toLowerCase().includes(query) ||
        term.long.toLowerCase().includes(query)
    );
  }, [allTerms, searchQuery]);

  // Group by first letter
  const groupedTerms = useMemo(
    () => groupByFirstLetter(filteredTerms),
    [filteredTerms]
  );

  // Get sorted letters
  const sortedLetters = useMemo(
    () => Array.from(groupedTerms.keys()).sort(),
    [groupedTerms]
  );

  return (
    <div className="relative min-h-screen bg-background">
      {/* Background effects */}
      <div className="pointer-events-none fixed inset-0 bg-gradient-cosmic opacity-50" />
      <div className="pointer-events-none fixed inset-0 bg-grid-pattern opacity-20" />

      <div className="relative mx-auto max-w-4xl px-6 py-8 md:px-12 md:py-12">
        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <Link
            href="/learn"
            className="flex items-center gap-2 text-muted-foreground transition-colors hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
            <span className="text-sm">Learning Hub</span>
          </Link>
        </div>

        {/* Hero section */}
        <div className="mb-8">
          <div className="mb-4 flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 shadow-lg shadow-primary/20">
              <BookOpen className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-2xl font-bold tracking-tight md:text-3xl">
                Glossary
              </h1>
              <p className="text-sm text-muted-foreground">
                {allTerms.length} terms defined
              </p>
            </div>
          </div>
          <p className="text-muted-foreground">
            Technical terms explained in plain language. Click any term to learn more.
          </p>
        </div>

        {/* Search */}
        <div className="relative mb-8">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search terms..."
            value={searchQuery}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchQuery(e.target.value)}
            className="w-full rounded-lg border border-border/50 bg-muted/30 px-4 py-2.5 pl-10 text-sm text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
          />
        </div>

        {/* Alphabet quick nav */}
        {!searchQuery && (
          <div className="mb-8 flex flex-wrap gap-1">
            {sortedLetters.map((letter) => (
              <a
                key={letter}
                href={`#letter-${letter}`}
                className="flex h-8 w-8 items-center justify-center rounded-lg bg-muted/50 text-sm font-mono font-medium text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary"
              >
                {letter}
              </a>
            ))}
          </div>
        )}

        {/* Results count when searching */}
        {searchQuery && (
          <div className="mb-6 text-sm text-muted-foreground">
            Found {filteredTerms.length} term{filteredTerms.length !== 1 ? "s" : ""} matching &quot;{searchQuery}&quot;
          </div>
        )}

        {/* Terms list */}
        {sortedLetters.length === 0 ? (
          <Card className="p-8 text-center">
            <p className="text-muted-foreground">No terms found matching your search.</p>
          </Card>
        ) : (
          <div className="space-y-8">
            {sortedLetters.map((letter) => (
              <section key={letter} id={`letter-${letter}`}>
                {/* Letter header */}
                <div className="sticky top-0 z-10 mb-4 flex items-center gap-3 bg-background/80 py-2 backdrop-blur-sm">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 font-mono text-xl font-bold text-primary">
                    {letter}
                  </div>
                  <div className="h-px flex-1 bg-border/50" />
                </div>

                {/* Terms in this letter group */}
                <div className="space-y-3">
                  {groupedTerms.get(letter)?.map((term) => (
                    <TermCard key={term.term} term={term} />
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}

        {/* Back to top */}
        <div className="mt-12 text-center">
          <a
            href="#"
            className="text-sm text-muted-foreground hover:text-primary"
          >
            Back to top ↑
          </a>
        </div>
      </div>
    </div>
  );
}

/**
 * Individual term card component
 */
function TermCard({ term }: { term: JargonTerm }) {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <Card
      id={getTermId(term.term)}
      className="overflow-hidden transition-all hover:border-primary/30"
    >
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="flex w-full items-start gap-4 p-4 text-left"
      >
        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
          <Lightbulb className="h-4 w-4" />
        </div>
        <div className="min-w-0 flex-1">
          <h3 className="font-semibold text-foreground">{term.term}</h3>
          <p className="mt-1 text-sm text-muted-foreground line-clamp-2">
            {term.short}
          </p>
        </div>
        <ChevronRight
          className={`mt-1 h-5 w-5 shrink-0 text-muted-foreground transition-transform ${
            isExpanded ? "rotate-90" : ""
          }`}
        />
      </button>

      {isExpanded && (
        <div className="border-t border-border/50 bg-muted/30 px-4 py-4">
          <div className="space-y-4 pl-12">
            {/* Full explanation */}
            <div>
              <h4 className="mb-1 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                What is it?
              </h4>
              <p className="text-sm leading-relaxed text-foreground">
                {term.long}
              </p>
            </div>

            {/* Analogy */}
            {term.analogy && (
              <div className="rounded-lg border border-primary/20 bg-primary/5 p-3">
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-primary">
                  Think of it like...
                </p>
                <p className="text-sm leading-relaxed text-foreground">
                  {term.analogy}
                </p>
              </div>
            )}

            {/* Why we use it */}
            {term.why && (
              <div className="rounded-lg border border-emerald-500/20 bg-emerald-500/5 p-3">
                <p className="mb-1 text-xs font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400">
                  Why we use it
                </p>
                <p className="text-sm leading-relaxed text-foreground">
                  {term.why}
                </p>
              </div>
            )}

            {/* Related terms */}
            {term.related && term.related.length > 0 && (
              <div>
                <h4 className="mb-2 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                  Related Terms
                </h4>
                <div className="flex flex-wrap gap-2">
                  {term.related.map((relatedTerm) => (
                    <a
                      key={relatedTerm}
                      href={`#${getTermId(relatedTerm)}`}
                      className="rounded-full border border-border/50 bg-muted/50 px-3 py-1 text-xs font-medium text-muted-foreground transition-colors hover:bg-primary/10 hover:text-primary"
                    >
                      {relatedTerm}
                    </a>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </Card>
  );
}
