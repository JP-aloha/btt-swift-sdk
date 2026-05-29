instrumentor:
	swift build -c release --product BTTInstrumentor --triple arm64-apple-macosx
	swift build -c release --product BTTInstrumentor --triple x86_64-apple-macosx
	lipo -create -output ../Sources/Artifacts/BTTInstrumentor.artifactbundle/bin/BTTInstrumentor .build/arm64-apple-macosx/release/BTTInstrumentor .build/x86_64-apple-macosx/release/BTTInstrumentor
	chmod +x ../Sources/Artifacts/BTTInstrumentor.artifactbundle/bin/BTTInstrumentor
	@echo "✅ Universal binary ready"
	@lipo -info ../Sources/Artifacts/BTTInstrumentor.artifactbundle/bin/BTTInstrumentor
