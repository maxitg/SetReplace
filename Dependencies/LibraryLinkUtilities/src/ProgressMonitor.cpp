/**
 * @file	ProgressMonitor.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Implementation file for ProgressMonitor class
 */
#include "LLU/ProgressMonitor.h"

#include "LLU/ErrorLog/ErrorManager.h"
#include "LLU/LibraryData.h"

namespace LLU {

	ProgressMonitor::ProgressMonitor(SharedTensor sharedIndicator, double step) : sharedIndicator(std::move(sharedIndicator)), step(step) {}

	double ProgressMonitor::get() const {
		return sharedIndicator[0];
	}

	void ProgressMonitor::set(double progressValue) {
		sharedIndicator[0] = progressValue;
		checkAbort();
	}

	double ProgressMonitor::getStep() const {
		return step;
	}

	void ProgressMonitor::setStep(double stepValue) {
		step = stepValue;
		checkAbort();
	}

	void ProgressMonitor::checkAbort() {
		if (LibraryData::API()->AbortQ() != 0) {
			ErrorManager::throwException(ErrorName::Aborted);
		}
	}

	ProgressMonitor& ProgressMonitor::operator++() {
		set(sharedIndicator[0] + step);
		return *this;
	}

	ProgressMonitor& ProgressMonitor::operator+=(double progress) {
		set(sharedIndicator[0] + progress);
		return *this;
	}

	ProgressMonitor& ProgressMonitor::operator--() {
		set(sharedIndicator[0] - step);
		return *this;
	}

	ProgressMonitor& ProgressMonitor::operator-=(double progress) {
		set(sharedIndicator[0] - progress);
		return *this;
	}

}  // namespace LLU